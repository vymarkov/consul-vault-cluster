#! /bin/bash

mkdir -p /tmp/vault

VAULT_PATH=${VAULT_PATH:-"/tmp/vault/config.json"}
secret_shares=${VAULT_SECRET_SHARES-5}
secret_threshold=${VAULT_SECRET_THESHOULD-3}

function unseal_vault() {
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

function init_vault() {  
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

function main() {
  state="/tmp/.machines.json"
  tfstate="$ROOT/terraform/consul/aws/terraform.tfstate"

  cat $tfstate | jq '.modules[0].resources | to_entries | map(select(.value.type == "aws_instance")) | map(.value.primary.attributes)' > $state

  leader="$(cat $state | jq -Mr 'map(.public_ip) | .[0]')"
  leadername="$(cat $state | jq --arg _ip $leader -rM 'map(select(.public_ip == $_ip)) | .[0] | .["tags.Name"]')"

  servers="$(cat $state | jq --arg leader $leader -rM 'map(.public_ip) | join(" ")')"
  
  consul_addr="$(cat $tfstate | jq -rM '.modules[0].outputs.consul_elb_address')"
  vault_advertize_addr="http://$leader:8200"
  
  for ip in $servers
  do 
    servername="$(cat $state | jq --arg _ip $ip -rM 'map(select(.public_ip == $_ip)) | .[0] | .["tags.Name"]')"
    if [ $servername != "null" ]; then
      echo $servername
      
      init_vault "http://$(docker-machine ip $servername):8200"  
    fi
  done  
  
  root_token="$(cat $VAULT_PATH | jq -rM .root_token)"
  echo ""
  echo "There is your root token: $root_token"  
}

main