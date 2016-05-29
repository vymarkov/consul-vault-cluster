variable "consul_ami" {
  default = "ami-26d5af4c"
}

variable "consul_instance_type" {
  default = "t2.nano"
}

variable "consul_key_path" {
  description = "Path to the private key specified by key_name."
  default     = "~/.ssh/id_rsa"
}

variable "key_name" {
  description = "Desired name of AWS key pair"
  type        = "string"
}

variable "consul_public_key_path" {
  description = "A public ssh key for use in a Consul cluster"
  type        = "string"
}

variable "consul_cluster_size" {
  description = "Desired count of servers in a Consul cluster"
  default     = 3
}

variable "consul_elb_health_check" {
  description = "A health check for Consul"
  default     = "HTTP:8500/v1/status/leader"
}

variable "vault_elb_health_check" {
  description = "A Vault health check"
  default     = "HTTP:8200/v1/sys/health?standbyok"
}
