resource "aws_instance" "vault_lb" {
  count                       = "1"
  ami                         = "${var.vault_ami}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${aws_key_pair.auth.id}"
  associate_public_ip_address = true
  availability_zone = "${element(split(",", lookup(var.aws_azs, var.aws_region)), count.index % length(split(",", lookup(var.aws_azs, var.aws_region))))}"

  connection {
    user = "ubuntu"
  }

  vpc_security_group_ids = [ 
    "${aws_security_group.docker.id}",
    "${aws_security_group.vault_elb.id}",
    "${aws_security_group.consul.id}"
  ]
  
  provisioner "local-exec" {
    command = <<EOF
    #! /bin/bash
    
    set -e
     
    dm="${format("vault-lb-%02d", count.index + 1)}"
        
    docker-machine rm -f $dm 2>/dev/null
    docker-machine create -d generic --generic-ssh-user ${var.aws_instance_user} --generic-ssh-port 22 --generic-ssh-key ${var.consul_key_path} --generic-ip-address ${self.public_ip} $dm
    docker-machine ssh $dm sudo adduser ubuntu docker
    
    eval $(docker-machine env --shell zsh $dm)
    docker version
    docker network create vault-lb-tier
    
    $ROOT/build-images.sh
    
    export DOCKER_MACHINE_IP="$(docker-machine ip $dm)"
    export DOMAIN_NAME=consul.${var.domain}
    export LETSENCRYPT_HOST=$DOMAIN_NAME
    export LETSENCRYPT_EMAIL=${var.letsenscrypt_email}
    export VAULT_LB_VIRTUAL_HOST=$DOMAIN_NAME
    export CONSUL_HTTP_ADDR="${aws_instance.consul_leader.public_ip}:8500"
    
    docker-machine ssh $dm sudo mkdir -p /etc/letsencrypt/proxy/certs
    docker-machine scp $ROOT/docker-compose/proxy/templates/nginx-compose-v2.tmpl $dm:/tmp/nginx-compose-v2.tmpl
    
    export CONSUL_AGENT_CONFIG='${template_file.consul_server_config.rendered}'
    export CONSUL_SERVER_LEADER="${aws_instance.consul_leader.public_ip}"
    
    CONSUL_AGENT_OPTS="-node $dm" docker-compose -f $ROOT/docker-compose/consul-agent.yml config
    CONSUL_AGENT_OPTS="-node $dm" docker-compose -f $ROOT/docker-compose/consul-agent.yml up -d
    
    CONSUL_HTTP_ADDR=agent:8500 docker-compose -f $ROOT/docker-compose/common.yml config
    CONSUL_HTTP_ADDR=agent:8500 docker-compose -f $ROOT/docker-compose/common.yml up -d
    
    docker-compose -f $ROOT/docker-compose/vault-lb.yml config
    docker-compose -f $ROOT/docker-compose/vault-lb.yml up -d
EOF
  }

  tags {
    Name = "${format("vault-lb-%02d", count.index + 1)}"
    role = "server"
  }
  
  depends_on = [ "aws_instance.consul_leader", "aws_instance.consul_server" ]
}
