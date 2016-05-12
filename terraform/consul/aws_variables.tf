variable "key_name" {
  description = "Desired name of AWS key pair"
  type = "string"
}

variable "consul_public_key_path" {
  description = "A public ssh key for use in a Consul cluster"
  type = "string"
}