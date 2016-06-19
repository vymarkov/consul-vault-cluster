#! /bin/bash

findAllConsulServers() {
  local machines=$(docker-machine ls --filter label=project_name=$1 --format '{{.Name}}')
  local servers;
  
  for machine in $machines; do 
    res=$(docker-machine inspect $machine | jq 'contains({HostOptions: { EngineOptions: { Labels: [ "service=consul" ] } }})')
    if [ "$res" == "true" ]; then
      servers=$machine
      break
    fi
  done
  echo "$servers"  
}

findConsulLeader() {
  local machines=$(docker-machine ls --filter label=project_name=$1 --format '{{.Name}}')
  local consul_leader;
  
  for machine in $machines; do 
    res=$(docker-machine inspect $machine | jq 'contains({HostOptions: { EngineOptions: { Labels: [ "service=consul",  "role=leader" ] } }})')
    if [ "$res" == "true" ]; then
      consul_leader=$machine
      break
    fi
  done
  echo "$consul_leader"   
}

findConsulServers() {
  local machines=$(docker-machine ls --filter label=project_name=$1 --format '{{.Name}}')
  local servers;
  
  for machine in $machines; do 
    res=$(docker-machine inspect $machine | jq 'contains({HostOptions: { EngineOptions: { Labels: [ "service=consul",  "role=follower" ] } }})')
    if [ "$res" == "true" ]; then
      servers="$servers $machine"
    fi
  done
  
  echo "$servers"
}

findVaultServers() {
  local machines=$(docker-machine ls --filter label=project_name=$1 --format '{{.Name}}')
  local servers;
  
  for machine in $machines; do 
    res=$(docker-machine inspect $machine | jq 'contains({HostOptions: { EngineOptions: { Labels: [ "service=vault", "role=server" ] } }})')
    if [ "$res" == "true" ]; then
      servers="$servers $machine"
    fi
  done
  
  echo "$servers"
}

findVaultLoadbalancer() {
  local machines=$(docker-machine ls --filter label=project_name=$1 --format '{{.Name}}')
  local vaultlb;
  
  for machine in $machines; do 
    res=$(docker-machine inspect $machine | jq 'contains({HostOptions: { EngineOptions: { Labels: [ "service=vault_lb", "role=lb" ] } }})')
    if [ "$res" == "true" ]; then
      vaultlb=$machine
      break
    fi
  done
  echo "$vaultlb"  
}