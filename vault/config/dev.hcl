backend "consul" {
  address = "consul-lb"
  path = "vault_dev"
  advertise_addr = "http://consul-lb:8200"
}

ha_backend "consul" {
  address = "consul-lb"
  path = "vault_ha"
  advertise_addr = "http://consul-lb:8200"
}

listener "tcp" {
 address = "0.0.0.0:8200"
 tls_disable = 1
}

disable_mlock = true