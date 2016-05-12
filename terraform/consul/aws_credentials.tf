provider "aws" {
  region = "us-east-1"
}

variable "consul_ami" {
  default = "ami-26d5af4c"
}

variable "consul_key_path" {
    description = "Path to the private key specified by key_name."
    default     = "~/.ssh/id_rsa"
}