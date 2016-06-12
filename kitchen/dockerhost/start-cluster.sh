#! /bin/bash

# Starts a cluster on single machine.
# ONLY FOR DEVELOPMENT PURPOSES

set -e

consul_backend_path=${VAULT_BACKEND_PATH:-'vault'}
consul_ha_backend_path=${VAULT_HA_BACKEND:-'vault_ha'} 
consul_master_token=${CONSUL_MASTER_TOKEN:-'secret'}
vault_token_id=

function add_acl_policy() {
  rules="key \"$consul_backend_path\" { policy = \"write\" } key \"$consul_ha_backend_path\" { policy = \"write\" }"
  vault_token_id=$(http -v --body PUT http://$DOCKER_MACHINE_IP:8500/v1/acl/create Name=vault Type=client Rules="$rules" token==$consul_master_token | jq -M -r .ID)
}

function create() {
  dockerComposeDir=$ROOT/docker-compose/dev
  
  (docker network rm vault-lb-tier) 2>/dev/null ||
  docker network create vault-lb-tier
  
  docker-compose -f $dockerComposeDir/consul-cluster.yml up -d
  CONSUL_AGENT_OPTS="-node consul-node-001" docker-compose -f $dockerComposeDir/consul-agent.yml up -d
  
  sleep 1
  
  add_acl_policy
  
  docker-compose -f $dockerComposeDir/common.yml up -d
  CONSUL_TOKEN=$vault_token_id CONSUL_ADDR=$DOCKER_MACHINE_IP:8500 docker-compose -f $dockerComposeDir/vault-cluster.yml up -d

  sleep 1
  echo "Init and unseal the vault servers..."
  $ROOT/vault/vault-init.sh cluster

  CONSUL_ADDR=agent:8500 docker-compose -f $dockerComposeDir/vault-lb.yml up -d
}

create
