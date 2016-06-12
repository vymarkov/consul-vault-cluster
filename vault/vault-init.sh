#!/bin/bash

# FOR DEVELOPMENT PURPOSES

set -e

mkdir -p /tmp/vault

VAULT_PATH=${VAULT_CONFIG_PATH:-"/tmp/vault/config.json"}
secret_shares=${VAULT_SECRET_SHARES-1}
secret_threshold=${VAULT_SECRET_THESHOULD-1}

init_services() {
  host_ip=$DOCKER_MACHINE_IP
  services=$(docker ps -f label=cluster=true -f label=env=dev -f label=cluster=true -f label=service=vault --format "{{.ID}}")
  for cid in $services
  do 
    conteiner_port="$(docker inspect --format '{{(index (index .NetworkSettings.Ports "8200/tcp") 0).HostPort}}' $cid)"
    init_vault "http://$host_ip:$conteiner_port"
  done
  
  vault_conf=$(cat $VAULT_PATH)
  root_token="$(echo $vault_conf | jq -r -M .root_token)"
  echo ""
  echo "Your root token: $root_token"
  echo ""
}

init_vault_server() {
  echo Init the Vault server using provided a $VAULT_ADDR env variable 
}

unseal_vault() {
  vault_addr=$1
  
  vault_conf=$(cat $VAULT_PATH)
  root_token="$(echo $vault_conf | jq -r -M .root_token)"
  keys="$(echo $vault_conf | jq -r -M .keys | jq -r -M 'join(" ")')" 

  for key in $keys; do
    resp=$(http -v --body PUT $vault_addr/sys/unseal key=$key)
  done

  sealstatus="$(http -v --body $vault_addr/sys/seal-status | jq .sealed)"
  if [ "$sealstatus" == "false" ]; then
    echo "Vault is initialized and unsealed"
  else
    echo "It looks doesn't right" 
  fi
}

init_vault() {  
  vault_addr=$1
  vault_endpoint="$vault_addr/v1"
  echo $vault_endpoint
  initialized="$(http -v --body $vault_endpoint/sys/init | jq .initialized)"
  if [ "$initialized" == "true" ]; then
    resp="$(http -v --body $vault_endpoint/sys/seal-status)"
    sealed="$(echo $resp | jq -r -M .sealed)"
    if [ "$sealed" == "true" ]; then
      echo "Vault server ($vault_addr) already initialized, but is unsealed"
      unseal_vault $vault_endpoint
    else
      echo "Vault server ($vault_addr) already initialized and unsealed"
    fi
  else
    echo Need to init and unseal Vault
    resp="$(http -v --body PUT $vault_endpoint/sys/init secret_shares:=$secret_shares secret_threshold:=$secret_threshold)"
    echo Storing the root token and unsealed keys into $VAULT_PATH
    echo $resp > $VAULT_PATH
    
    unseal_vault $vault_endpoint
  fi
}

init_services