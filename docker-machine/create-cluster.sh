#! /bin/bash

set -e

source $ROOT/docker-machine/lib.sh
source $ROOT/vault/lib.sh

##### Global Variables
CONSUL_CLUSTER_SIZE=${CONSUL_CLUSTER_SIZE:-3}

export SHELL=${SHELL:-"$(which zsh)"}
export DOCKER_MACHINE_IP=
export CONSUL_SERVER_OPTS=
export CONSUL_AGENT_OPTS=
export CONSUL_SERVER_PRIMARY=
export BOOTSTRAP_EXPECT=$CONSUL_CLUSTER_SIZE

export CONSUL_MASTER_TOKEN=${CONSUL_MASTER_TOKEN:-'secret'}
export CONSUL_SERVER_CONFIG_TEMPLATE=${CONSUL_SERVER_CONFIG_TEMPLATE:-$ROOT/docker-compose/dev/consul/consul_server.json}
export CONSUL_AGENT_CONFIG_TEMPLATE=${CONSUL_AGENT_CONFIG_TEMPLATE:-$ROOT/docker-compose/dev/consul/consul_agent.json}

export CONSUL_BACKEND_ADDR=
export VAULT_ADVERTISE_ADDR=

export DOMAIN_NAME=vault.example.com
export LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL:-'me@example.com'}

export project_name="phoenix"
export vault_advertize_addr=$1

#### Functions

function configure_consul_server {
  echo $1
  
  DOCKER_MACHINE_IP=$(docker-machine ip $1)
  CONSUL_SERVER_OPTS="-rejoin --retry-join $(docker-machine ip $2) -node $1"
  config=$(envsubst < $CONSUL_SERVER_CONFIG_TEMPLATE)
  
  CONSUL_SERVER_CONFIG=$config docker-compose -f "$ROOT/docker-compose/consul-server.yml" config
  CONSUL_SERVER_CONFIG=$config docker-compose -f "$ROOT/docker-compose/consul-server.yml" up -d
}

function configure_consul_leader {
  echo $1
  
  eval $(docker-machine env --shell bash $1)
  $ROOT/build-images.sh
  
  DOCKER_MACHINE_IP="$(docker-machine ip $1)"
  BOOTSTRAP_EXPECT=1
  CONSUL_SERVER_OPTS="-bootstrap-expect $BOOTSTRAP_EXPECT -node $1"
  export CONSUL_SERVER_CONFIG=$(envsubst < $CONSUL_SERVER_CONFIG_TEMPLATE)
  
  docker-compose -f "$ROOT/docker-compose/consul-server.yml" config
  docker-compose -f "$ROOT/docker-compose/consul-server.yml" up -d
}

function create_consul_cluster() {
  # Consul Server Cluster using docker machine
  leadername="$(findConsulLeader $project_name)"
  leader=$(docker-machine ip $leadername)
  
  configure_consul_leader $leadername
 
  for srv in $(findConsulServers $project_name); do
    eval $(docker-machine env --shell bash $srv)
    $ROOT/build-images.sh
  
    configure_consul_server $srv $leadername
  done  
}

function configure_vault_server() {
  echo $1; echo
  
  VAULT_ADDR=${vault_advertize_addr:-"http://$(docker-machine ip $1):8200"}
  CONSUL_ADDR="$(docker-machine ip $2):8500"
  DOCKER_MACHINE_IP=$(docker-machine ip $1)
  CONSUL_AGENT_OPTS="-node $1"
  
  export CONSUL_SERVER_LEADER=$(docker-machine ip $2)
  export CONSUL_AGENT_CONFIG=$(envsubst < $CONSUL_AGENT_CONFIG_TEMPLATE)
  
  docker-compose -f "$ROOT/docker-compose/consul-agent.yml" config
  docker-compose -f "$ROOT/docker-compose/consul-agent.yml" up -d
  
  export CONSUL_HTTP_ADDR='agent:8500'
  
  docker-compose -f "$ROOT/docker-compose/common.yml" config
  docker-compose -f "$ROOT/docker-compose/common.yml" up -d
  
  CONSUL_TOKEN=$CONSUL_MASTER_TOKEN docker-compose -f "$ROOT/docker-compose/vault.yml" config
  CONSUL_TOKEN=$CONSUL_MASTER_TOKEN docker-compose -f "$ROOT/docker-compose/vault.yml" up -d
  
  sleep 1
  
  init_vault "http://$(docker-machine ip $1):8200"
}

function create_vault_cluster() {
  local servers=$(findVaultServers $project_name)
  echo $servers

  local consul_leader="$(findConsulLeader $project_name)"
  local vault_leader=$(echo $servers | cut -d" " -f1)
  
  for srv in $servers;
  do
    eval $(docker-machine env --shell bash $srv)
    $ROOT/build-images.sh
    
    configure_vault_server $srv $consul_leader
  done
}

function configure_vault_lb() {
  local consul_leader="$(findConsulLeader $project_name)"
  local lb=$(findVaultLoadbalancer $project_name)
  
  eval $(docker-machine env --shell bash $lb)
  
  ex=$(docker network ls -f name=vault-lb-tier -q)
  if [ -z "ex" ]; then
    docker network create vault-lb-tier
  fi
  
  $ROOT/build-images.sh
  
  DOCKER_MACHINE_IP=$(docker-machine ip $lb)
  CONSUL_AGENT_OPTS="-node $lb"
  
  export CONSUL_SERVER_LEADER=$(docker-machine ip $consul_leader)
  export CONSUL_AGENT_CONFIG=$(envsubst < $CONSUL_AGENT_CONFIG_TEMPLATE)
  
  docker-compose -f "$ROOT/docker-compose/consul-agent.yml" config
  docker-compose -f "$ROOT/docker-compose/consul-agent.yml" up -d
  
  export CONSUL_HTTP_ADDR='agent:8500'
  
  docker-compose -f "$ROOT/docker-compose/common.yml" config
  docker-compose -f "$ROOT/docker-compose/common.yml" up -d
  
  docker-machine ssh $lb sudo mkdir -p /etc/letsencrypt/proxy/certs
  docker-machine scp $ROOT/docker-compose/proxy/templates/nginx-compose-v2.tmpl $lb:/tmp/nginx-compose-v2.tmpl
    
  export LETSENCRYPT_HOST=$DOMAIN_NAME
  export LETSENCRYPT_EMAIL=$LETSENCRYPT_EMAIL
  export VAULT_LB_VIRTUAL_HOST=$DOMAIN_NAME
  export CONSUL_HTTP_ADDR="$(docker-machine ip $consul_leader):8500"
  export CONSUL_TOKEN=$CONSUL_MASTER_TOKEN
    
  docker-compose -f $ROOT/docker-compose/vault-lb.yml config
  docker-compose -f $ROOT/docker-compose/vault-lb.yml up -d
}

function print_consul_webui_endpoint() {
  echo "Consul Cluster Web UI URL :"
  echo "---------------------------"
  
  for srv in $(findAllConsulServers $project_name); do
    echo "http://$(docker-machine ip $srv):8500/ui"
  done
}


##### MAIN SCRIPT #############
create_consul_cluster
create_vault_cluster
configure_vault_lb
print_consul_webui_endpoint