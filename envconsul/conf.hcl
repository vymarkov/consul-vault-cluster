vault {
  address = "http://192.168.99.100:8200"
  token   = "697039e8-a95e-b841-a8b6-77e8f2cb0e82" // May also be specified via the envvar VAULT_TOKEN
  renew   = false
}

secret {
  path = "secret/database"
}