vault {
  // This is the address of the Vault leader. The protocol (http(s)) portion
  // of the address is required.
  address = "http://192.168.99.100:8200"

  // This is the token to use when communicating with the Vault server.
  // Like other tools that integrate with Vault, Consul Template makes the
  // assumption that you provide it with a Vault token; it does not have the
  // incorporated logic to generate tokens via Vault's auth methods.
  //
  // This value can also be specified via the environment variable VAULT_TOKEN.
  token = "697039e8-a95e-b841-a8b6-77e8f2cb0e82"

  // This option tells Consul Template to automatically renew the Vault token
  // given. If you are unfamiliar with Vault's architecture, Vault requires
  // tokens be renewed at some regular interval or they will be revoked. Consul
  // Template will automatically renew the token at half the lease duration of
  // the token. The default value is true, but this option can be disabled if
  // you want to renew the Vault token using an out-of-band process.
  //
  // Note that secrets specified in a template (using {{secret}} for example)
  // are always renewed, even if this option is set to false. This option only
  // applies to the top-level Vault token itself.
  renew = false
}