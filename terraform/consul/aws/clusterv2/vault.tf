resource "aws_instance" "vault_server" {
  count                       = "1"
  ami                         = "${var.consul_ami}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${aws_key_pair.auth.id}"
  associate_public_ip_address = true
  availability_zone = "${element(split(",", lookup(var.aws_azs, var.aws_region)), count.index % length(split(",", lookup(var.aws_azs, var.aws_region))))}"

  connection {
    user = "ubuntu"
  }

  vpc_security_group_ids = [ 
    "${aws_security_group.docker.id}", 
    "${aws_security_group.vault.id}",
    "${aws_security_group.consul.id}"
  ]
  
  provisioner "local-exec" {
    command = <<EOF
    #! /bin/bash
    
    set -e
    
    dm="${format("vault-server-%02d", count.index + 1)}"
        
    docker-machine rm -f $dm 2>/dev/null
    docker-machine create -d generic --generic-ssh-user ${var.aws_instance_user} --generic-ssh-port 22 --generic-ssh-key ${var.consul_key_path} --generic-ip-address ${self.public_ip} $dm
    
    eval $(docker-machine env --shell zsh $dm)
    
    $ROOT/build-images.sh
        
    export CONSUL_AGENT_CONFIG='${template_file.consul_agent_config.rendered}'
    export CONSUL_SERVER_LEADER="${aws_instance.consul_leader.public_ip}"
    
    ${path.module}/scripts/prov_vault.sh $dm ${var.domain} ${var.consul_master_token} ${aws_instance.consul_leader.public_ip}
EOF
  }

  tags {
    Name = "${format("vault-server-%02d", count.index + 1)}"
    role = "server"
  }
  
  depends_on = [ "aws_key_pair.auth" ]
}