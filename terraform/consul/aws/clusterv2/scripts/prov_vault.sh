#!/bin/bash

set -e

dm=$1
domain=${DOMAIN:-$2}
consul_master_token=${CONSUL_SERVER_LEADER:-$3}
export CONSUL_SERVER_LEADER=${CONSUL_SERVER_LEADER:-$4}
    
eval $(docker-machine env --shell zsh $dm)

export CONSUL_SERVER_LEADER=$4    
export DOCKER_MACHINE_IP="$(docker-machine ip $dm)"
    
CONSUL_AGENT_OPTS="-node $dm" docker-compose -f $ROOT/docker-compose/consul-agent.yml config
CONSUL_AGENT_OPTS="-node $dm" docker-compose -f $ROOT/docker-compose/consul-agent.yml up -d
    
CONSUL_HTTP_ADDR=agent:8500 docker-compose -f $ROOT/docker-compose/common.yml config
CONSUL_HTTP_ADDR=agent:8500 docker-compose -f $ROOT/docker-compose/common.yml up -d
    
export VAULT_ADDR="https://vault.${domain}"
#export VAULT_ADDR="http://${self.public_ip}:8200"
export CONSUL_ADDR=$CONSUL_SERVER_LEADER:8500
export CONSUL_TOKEN="${consul_master_token}"
    
docker-compose -f $ROOT/docker-compose/vault-leader.yml config
docker-compose -f $ROOT/docker-compose/vault-leader.yml up -d
    
vault_addr="http://$(docker-machine ip $dm):8200"

# echo $vault_addr
#$ROOT/vault/init_vault.sh $vault_addr