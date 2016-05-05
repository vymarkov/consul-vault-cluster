#! /bin/bash

. ./variables.sh

# BOOTSTRAP_EXPECT=2 docker-compose -f docker-compose/consul-server.yml config
# exit 0

#### Functions

function cleanup_docker_containers() {
  # Kill and remove containers on the node
  if [ $(docker ps -q | wc -l) > 0 ]; then
    docker kill $(docker ps -q)
  fi

  if [ $(docker ps -aq | wc -l) > 0 ]; then
    docker rm $(docker ps -aq)
  fi
}

function run_consul_server() {
  eval $(docker-machine env $1)
  # cleanup_docker_containers
  DOCKER_MACHINE_IP="$(docker-machine ip $1)"
  if [ "$2" = "1" ]; then
    CONSUL_SERVER_OPTS="-node $1" 
    # docker run -d --net host --name=$1 gliderlabs/consul-server -advertise $(docker-machine ip $1) -bootstrap-expect=3
  else
    CONSUL_SERVER_OPTS="-rejoin --retry-join $(docker-machine ip consul-server-01) -node $1"
    # docker run -d --net host --name=$1 gliderlabs/consul-server -advertise $(docker-machine ip $1) -join $(docker-machine ip consul-server-01)
  fi
  docker-compose -f docker-compose/consul-server.yml up -d
}

function run_consul_agent() {
  eval $(docker-machine env $1)
  # cleanup_docker_containers
  CONSUL_SERVER_PRIMARY="$(docker-machine ip consul-server-01)"
  DOCKER_MACHINE_IP="$(docker-machine ip $1)"
  docker-compose -f docker-compose/consul-agent.yml config
  docker-compose -f docker-compose/consul-agent.yml up -d
  # docker run -d --net host --name=$1 gliderlabs/consul-agent -advertise $(docker-machine ip $1) -join $(docker-machine ip consul-server-01)
}


function create_and_configure_host() {
  # create a node using docker-machine
  cmd="docker-machine create --driver virtualbox --virtualbox-memory "512" --engine-label consul=server $1"  
  echo "$cmd"
  if [ "$2" == "server" ]; then
    docker-machine create --driver virtualbox --virtualbox-memory "512" --engine-label consul=server $1
  else
    docker-machine create --driver virtualbox --virtualbox-memory "512" --engine-label consul=agent $1
  fi  
  # Start the node if it is not Running
  docker-machine start $1
  # Install Python in Boot2Docker VM
  # docker-machine ssh $1 "tce-load -w -i python.tcz"
  # add python symbolic link in /usr/bin/python as ansible looks at that location
  # docker-machine ssh $1 "sudo ln -s /usr/local/bin/python /usr/bin/python"
  # Install pip and docker-py in boot2docker VM
  # docker-machine ssh $1 "rm -rf get-pip.py && wget https://bootstrap.pypa.io/get-pip.py && sudo python get-pip.py && sudo pip install docker-py"
}

function create_consul_cluster() {
  # Consul Server Cluster using docker machine
  for i in $(eval echo "{1..$CONSUL_CLUSTER_SIZE}")
  do
    SERVER_NAME="consul-server-0$i"
  	create_and_configure_host $SERVER_NAME "server"
    run_consul_server $SERVER_NAME "$i"
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
  # echo "http://$(docker-machine ip consul-server-01):8500/ui"
  
  for i in $(docker-machine ls --filter label=consul=server --format {{.Name}})
  do
    echo "http://$(docker-machine ip $i):8500/ui"
  done
}


##### MAIN SCRIPT #############
create_consul_cluster
create_consul_agents
print_consul_webui_endpoint
