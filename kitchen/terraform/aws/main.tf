# RUN THIS TERRAFORM PLAN FROM KITCHEN DOCKER CONTAINER TO AVOID ERRORS IN RUN TIME

provider "aws" {
  region = "us-east-1"
}

variable "ami" { default = "ami-26d5af4c" }
variable "instance_type" { default = "t2.micro" }
variable "aws_instance_user" { default = "ubuntu" }
variable "docker_machine_name" { default = "dev-aws" }
variable "letsenscrypt_email" { default = "me@example.com" }

variable "vault_backend_path" { default = "vault" }
variable "vault_ha_backend_path" { default = "vault_ha" }

variable "consul_master_token" { default = "secret" }

variable "dev_public_key_path" {
  description = "Path to the private key specified by key_name."
  default     = "~/.ssh/id_rsa.pub"
}

variable "dev_private_key_path" {
  default = "~/.ssh/id_rsa"
}

resource "aws_key_pair" "dev_key_pair" {
  key_name   = "consul"
  public_key = "${file(var.dev_public_key_path)}"
}

resource "aws_security_group" "dev" {
  name        = "docker"
  description = "A Consul+Vault cluster dev security group"

  # SSH port
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Web http port  
  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # The Vault Server
  ingress {
    from_port   = "8200"
    to_port     = "8200"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Docker Host port 
  ingress {
    from_port   = "2376"
    to_port     = "2376"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # The port range for Docker
  ingress {
    from_port   = "32768"
    to_port     = "61000"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # The Server RPC server
  ingress {
    from_port   = 8300
    to_port     = 8300
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # The Serf LAN port
  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # The Serf LAN port
  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # The Serf WAN port
  ingress {
    from_port   = 8302
    to_port     = 8302
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # The Serf WAN port
  ingress {
    from_port   = 8302
    to_port     = 8302
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # The CLI RPC endpoint
  ingress {
    from_port   = 8400
    to_port     = 8400
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # The HTTP API / UI
  ingress {
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # The DNS server
  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # The DNS server
  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags {
    Name = "Consul+Vault development"
    env  = "development"
  }
}

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

resource "template_file" "vault_acl_rules" {
  template = <<EOF
  key "${vault_backend_path}" {
    policy = "write"    
  } 
  
  key "${vault_ha_backend_path}" {
    policy = "write"
  }
EOF

  vars {
    vault_ha_backend_path = "${var.vault_ha_backend_path}"
    vault_backend_path    = "${var.vault_backend_path}"
  }
}

resource "aws_instance" "dev" {
  count                       = "1"
  ami                         = "${var.ami}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${aws_key_pair.dev_key_pair.id}"
  associate_public_ip_address = true
  
  root_block_device = {
    volume_type = "standard"
    volume_size = 16
    delete_on_termination = false
  }

  connection {
    host = "${aws_instance.dev.public_ip}" 
    user = "${var.aws_instance_user}"
    private_key = "${var.dev_private_key_path}"
  }

  vpc_security_group_ids = [ "${aws_security_group.dev.id}" ]
  
  provisioner "local-exec" {
    command = <<EOF
    set -e
    
    rm ~/.ddnsrc-testing.json 2>/dev/null
    docker-machine rm -f ${var.docker_machine_name} 2>/dev/null
    docker-machine create -d generic --generic-ssh-user ${var.aws_instance_user} --generic-ssh-port 22 --generic-ssh-key ${var.dev_private_key_path} --generic-ip-address ${aws_instance.dev.public_ip} ${var.docker_machine_name}
    docker-machine ssh ${var.docker_machine_name} sudo adduser ubuntu docker
    ddns-testing --random --agree --email ${var.letsenscrypt_email} --answer ${aws_instance.dev.public_ip} --type A
    
    domain="$(cat ~/.ddnsrc-testing.json | jq -M -r .hostname)"
    export DOMAIN_NAME=$domain
    
    eval $(docker-machine env --shell zsh ${var.docker_machine_name})
    docker version
    docker network create vault-lb-tier
    
    $ROOT/build-images.sh
    
    export CONSUL_SERVER_CONFIG='${template_file.consul_server_config.rendered}'
    export CONSUL_AGENT_CONFIG='${template_file.consul_agent_config.rendered}'
    
    docker-compose -f $ROOT/docker-compose/dev/consul-cluster.yml config 
    docker-compose -f $ROOT/docker-compose/dev/consul-cluster.yml up -d
    
    CONSUL_AGENT_OPTS="-node consul-node-01" docker-compose -f $ROOT/docker-compose/dev/consul-agent.yml config
    CONSUL_AGENT_OPTS="-node consul-node-01" docker-compose -f $ROOT/docker-compose/dev/consul-agent.yml up -d
    
    export DOCKER_MACHINE_IP="$(docker-machine ip $(docker-machine active))"
    
    docker-compose -f $ROOT/docker-compose/dev/common.yml config
    docker-compose -f $ROOT/docker-compose/dev/common.yml up -d
    
    sleep 3
    
    consul_token=$(http -v --body PUT http://$DOCKER_MACHINE_IP:8500/v1/acl/create Name=vault Type=client Rules="${template_file.vault_acl_rules.rendered}" token==${var.consul_master_token} | jq -M -r .ID)
    
    echo "Your consul token for the Vault server: $consul_token"
    
    export VAULT_ADDR="https://$domain"
    export CONSUL_ADDR="$(docker-machine ip $(docker-machine active)):8500"
    
    CONSUL_TOKEN=$consul_token docker-compose -f $ROOT/docker-compose/dev/vault-cluster.yml config
    CONSUL_TOKEN=$consul_token docker-compose -f $ROOT/docker-compose/dev/vault-cluster.yml up -d
    
    docker-machine ssh ${var.docker_machine_name} sudo mkdir -p /etc/letsencrypt/proxy/certs
    docker-machine scp $ROOT/docker-compose/proxy/templates/nginx-compose-v2.tmpl ${var.docker_machine_name}:/tmp/nginx-compose-v2.tmpl
    
    export LETSENCRYPT_HOST=$DOMAIN_NAME
    export LETSENCRYPT_EMAIL=${var.letsenscrypt_email}
    export VAULT_LB_VIRTUAL_HOST=$DOMAIN_NAME
    
    docker-compose -f $ROOT/docker-compose/dev/vault-lb.yml config
    docker-compose -f $ROOT/docker-compose/dev/vault-lb.yml up -d
    
    # After has been applied the terraform plan you need to init and unseal the Vault server by yourself
    # You can use $ROOT/vault/vault-init.sh script for this purpose or another way
EOF
  }
  
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update"
    ]
  }

  tags {
    Name = "consul-vault-dev-machine"
    env  = "development"
  }
}

output "aws_development_machine_ip" {
  value = "${aws_instance.dev.public_ip}"
}

output "consul_master_token" {
  value = "${var.consul_master_token}"
}