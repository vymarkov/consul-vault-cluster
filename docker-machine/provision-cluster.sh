#! /bin/bash

set -e

##### Global Variables
CONSUL_CLUSTER_SIZE=${CONSUL_CLUSTER_SIZE:-3}
CONSUL_AGENTS=${CONSUL_AGENTS:-1}

export SHELL=${SHELL:-"$(which zsh)"}
export DOCKER_MACHINE_IP=
export CONSUL_IMAGE=vymarkov/consul:0.6.4
export CONSUL_SERVER_OPTS=
export CONSUL_AGENT_OPTS=
export CONSUL_SERVER_PRIMARY=
export BOOTSTRAP_EXPECT=$CONSUL_CLUSTER_SIZE

export CONSUL_BACKEND_ADDR=
export VAULT_ADVERTISE_ADDR=
export VAULT_IMAGE=

tfstate="$ROOT/terraform/consul/aws/terraform.tfstate"
CONSUL_IMAGE="$(cat $tfstate | jq -rM '.modules[0].outputs.consul_repository_url' | cut -c 9-)"
VAULT_IMAGE="$(cat $tfstate | jq -rM '.modules[0].outputs.vault_repository_url' | cut -c 9-)"

#### Functions

function run_consul_server() {
  eval $(docker-machine env $1)
  echo "Runing a consul server on $1 server... (leader : $2)"
 
  DOCKER_MACHINE_IP="$(docker-machine ip $1)"
  if [ "$1" = "$2" ]; then
    CONSUL_SERVER_OPTS="-bootstrap-expect $BOOTSTRAP_EXPECT -node server-leader" 
  else
    CONSUL_SERVER_OPTS="-rejoin --retry-join $(docker-machine ip $2) -node $1"
  fi
  
  docker-compose -f "$ROOT/docker-compose/consul-server.yml" config 
  docker-compose -f "$ROOT/docker-compose/consul-server.yml" up -d
}

function run_vault_server() {
  eval $(docker-machine env $1)
  echo "Runing a vault server on $1 server..."
  
  CONSUL_BACKEND_ADDR=$2
  VAULT_ADVERTISE_ADDR=$3
  docker-compose -f "$ROOT/docker-compose/vault-leader.yml" config
  docker-compose -f "$ROOT/docker-compose/vault-leader.yml" up -d
}

function run_consul_agent() {
  eval $(docker-machine env $1)
  
  # CONSUL_SERVER_PRIMARY="$(docker-machine ip consul-server-01)"
  # DOCKER_MACHINE_IP="$(docker-machine ip $1)"
  # docker-compose -f docker-compose/consul-agent.yml config
  # docker-compose -f docker-compose/consul-agent.yml up -d
}

function configure_host() {
  echo $1 
}

function create_consul_cluster() {
  # Consul Server Cluster using docker machine
  $(aws ecr get-login)
  
  state="/tmp/.machines.json"
  tfstate="$ROOT/terraform/consul/aws/terraform.tfstate"

  cat $tfstate | jq '.modules[0].resources | to_entries | map(select(.value.type == "aws_instance")) | map(.value.primary.attributes)' > $state

  leader="$(cat $state | jq -Mr 'map(.public_ip) | .[0]')"
  leadername="$(cat $state | jq --arg _ip $leader -rM 'map(select(.public_ip == $_ip)) | .[0] | .["tags.Name"]')"
  # echo $leadername
  # exit 0
  servers="$(cat $state | jq --arg leader $leader -rM 'map(.public_ip) | join(" ")')"
  
  # TODO: cut a consul address
  # for use in vault config we need to provide
  # a consul address without a protocol schema
  # use cut for this goal is bad way, need to refactore
  consul_addr="$(cat $tfstate | jq -rM '.modules[0].outputs.consul_elb_address' | cut -c 8-)"
  vault_advertize_addr="http://$leader:8200"
  
  for ip in $servers
  do 
    servername="$(cat $state | jq --arg _ip $ip -rM 'map(select(.public_ip == $_ip)) | .[0] | .["tags.Name"]')"
    if [ $servername != "null" ]; then
      configure_host $servername $leadername
      run_consul_server $servername $leadername
      run_vault_server $servername $consul_addr $vault_advertize_addr
    fi
  done  
}

function create_consul_agents() {
  # Consul Agents using docker macine
  for i in $(eval echo "{1..$CONSUL_AGENTS}")
  do
    SERVER_NAME="consul-agent-0$i"
  	create_and_configure_host $SERVER_NAME
    run_consul_agent $SERVER_NAME
  done
}

function print_consul_webui_endpoint() {
  echo "Consul Cluster Web UI URL :"
  echo "---------------------------"
  
  for i in $(docker-machine ls --filter label=consul=server --format {{.Name}})
  do
    echo "http://$(docker-machine ip $i):8500/ui"
  done
}


##### MAIN SCRIPT #############
create_consul_cluster

# create_consul_agents
# print_consul_webui_endpoint
