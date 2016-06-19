resource "template_file" "consul_server_config" {
  template = <<EOF
  {
	  "datacenter": "dc1",
	  "acl_datacenter": "dc1",
	  "acl_default_policy": "deny",
	  "acl_master_token": "${consul_master_token}"
  }  
EOF

  vars {
    consul_master_token = "${var.consul_master_token}"
  }
}

resource "template_file" "consul_agent_config" {
  template = <<EOF
  {
	  "datacenter": "dc1",
	  "acl_token": "${consul_master_token}"
  }  
EOF

  vars {
    consul_master_token = "${var.consul_master_token}"
  }
}

resource "aws_instance" "consul_leader" {
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
    "${aws_security_group.consul.id}",
    "${aws_security_group.vault.id}"
  ]
  
  provisioner "local-exec" {
    command = <<EOF
    #! /bin/bash
    
    set -e
    
    dm="${format("consul-server-%02d", count.index + 1)}"
        
    docker-machine rm -f $dm 2>/dev/null
    docker-machine create -d generic --generic-ssh-user ${var.aws_instance_user} --generic-ssh-port 22 --generic-ssh-key ${var.consul_key_path} --generic-ip-address ${self.public_ip} $dm
    
    eval $(docker-machine env --shell zsh $dm)
    
    $ROOT/build-images.sh
    
    export CONSUL_SERVER_CONFIG='${template_file.consul_server_config.rendered}'
    export DOCKER_MACHINE_IP="$(docker-machine ip $dm)"
    export BOOTSTRAP_EXPECT=${var.consul_cluster_size}
    export BOOTSTRAP_EXPECT=1
    export CONSUL_SERVER_OPTS="-bootstrap-expect $BOOTSTRAP_EXPECT -node $dm"
    
    docker-compose -f "$ROOT/docker-compose/consul-server.yml" config
    docker-compose -f "$ROOT/docker-compose/consul-server.yml" up -d
EOF
  }

  tags {
    Name = "${format("consul-server-%02d", count.index + 1)}"
    role = "server"
  }
  
  depends_on = [ "aws_key_pair.auth", "template_file.consul_server_config" ]
}


resource "aws_instance" "consul_server" {
  count                       = "${var.consul_cluster_size - 1}"
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
    "${aws_security_group.consul.id}",
    "${aws_security_group.vault.id}"
  ]
  
  provisioner "local-exec" {
    command = <<EOF
    #! /bin/bash
    
    set -e
    
    dm="${format("consul-server-%02d", count.index + 2)}"
        
    docker-machine rm -f $dm 2>/dev/null
    docker-machine create -d generic --generic-ssh-user ${var.aws_instance_user} --generic-ssh-port 22 --generic-ssh-key ${var.consul_key_path} --generic-ip-address ${self.public_ip} $dm
    
    eval $(docker-machine env --shell zsh $dm)
    
    $ROOT/build-images.sh
    
    export CONSUL_SERVER_CONFIG='${template_file.consul_server_config.rendered}'
    export DOCKER_MACHINE_IP="$(docker-machine ip $dm)"
    export CONSUL_SERVER_OPTS="-rejoin --retry-join ${aws_instance.consul_leader.public_ip} -node $dm"
    
    docker-compose -f "$ROOT/docker-compose/consul-server.yml" config
    docker-compose -f "$ROOT/docker-compose/consul-server.yml" up -d 
EOF
  }

  tags {
    Name = "${format("consul-server-%02d", count.index + 2)}"
    role = "server"
  }
  
  depends_on = [ "aws_key_pair.auth", "template_file.consul_agent_config" ]
}

output consul_leader {
  value = "${aws_instance.consul_leader.public_ip}"
}