{{ with $vault_backend := getenv "VAULT_BACKEND" }} {{ if eq $vault_backend "consul" }}
backend "consul" {
  address = "{{ getenv "VAULT_BACKEND_ADDR" "127.0.0.1" }}"
  path    = "{{ getenv "VAULT_BACKEND_PATH" "vault" }}"
  advertise_addr = "{{ getenv "VAULT_ADVERTISE_ADDR" "http://127.0.0.1:8200" }}"
} {{ end }} {{ end }}

{{ with $vault_ha_backend := getenv "VAULT_HA_BACKEND" }} {{ if eq $vault_ha_backend "consul" }}
ha_backend "consul" {
  address = "{{ getenv "VAULT_HA_BACKEND_ADDR" "127.0.0.1" }}"
  path    = "{{ getenv "VAULT_HA_BACKEND_PATH" "vault_ha" }}"
  advertise_addr = "{{ getenv "VAULT_ADVERTISE_ADDR" "http://127.0.0.1:8200" }}"
} {{ end }} {{ end }}

listener "tcp" {
  address = "{{ getenv "LISTENER_ADDR" "0.0.0.0:8200" }}"
  tls_disable = "{{ getenv "LISTENER_TLS_DISABLE" "1" }}"
}

disable_mlock = true