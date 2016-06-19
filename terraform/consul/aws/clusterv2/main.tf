provider "aws" {
  region = "${var.aws_region}"
}

variable aws_region { default = "us-east-1" }

variable aws_azs {
  default = { 
    us-east-1 = "us-east-1a,us-east-1b,us-east-1d,us-east-1e"
  }
}

resource "aws_key_pair" "auth" {
  key_name   = "consul_"
  public_key = "${file(var.consul_public_key_path)}"
}
