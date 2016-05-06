#!/bin/bash

versionapi="v1"
vaultserver="$VAULT_ADDR/$versionapi"
secret_shares=${VAULT_SECRET_SHARES-1}
secret_threshold=${VAULT_SECRET_THESHOULD-1}
 
initialized="$(http -v --body $vaultserver/sys/init | jq .initialized)"
if [ "$initialized" == "true" ]; then
  echo "Vault already initialized."
  exit 0
fi

resp="$(http -v --body PUT $vaultserver/sys/init secret_shares:=$secret_shares secret_threshold:=$secret_threshold)"
echo "Storing the root token and unsealed keys into vault.json"
echo $resp > vault.json

root_token="$(echo $resp | jq -r -M .root_token)"
keys="$(echo $resp | jq -r -M .keys | jq -r -M 'join(" ")')" 

for key in $keys; do
  http -v --body PUT $vaultserver/sys/unseal key=$key
done

sealstatus="$(http -v --body $vaultserver/sys/seal-status | jq .sealed)"
if [ "$sealstatus" == "false" ]; then
  echo "Vault is initialized and unsealed"
  echo ""
  echo "Your root token: $root_token"
else
  echo "It looks doesn't right" 
fi