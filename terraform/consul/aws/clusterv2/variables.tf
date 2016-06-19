variable aws_instance_user { default = "ubuntu" }
variable instance_type { default = "t2.micro" }

variable route53_zone_id { default = "Z1RC2MMIGFWYGO" }
variable domain { default = "lazyorange.xyz" }
variable letsenscrypt_email { default = "me@example.com" }

variable vault_backend_path { default = "vault" }
variable vault_ha_backend_path { default = "vault_ha" }

variable consul_master_token { default = "secret" }
variable consul_ami { default = "ami-26d5af4c" }
variable vault_ami { default = "ami-26d5af4c" }

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
