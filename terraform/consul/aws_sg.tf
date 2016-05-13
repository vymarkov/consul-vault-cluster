resource "aws_security_group" "docker" {
  name        = "docker"
  description = "A Docker security group"
  vpc_id      = "${module.vpc.vpc_id}"
  
  # SSH port
  ingress {
    from_port   = "22"
    to_port     = "22"
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
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "consul" {
  name        = "consul"
  description = "A Consul security group"
  vpc_id      = "${module.vpc.vpc_id}"
  
  # The DNS server
  ingress {
    from_port   = "53"
    to_port     = "53"
    protocol    = "udp"
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
  
}