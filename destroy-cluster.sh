#! /bin/bash

remove_DM_by_label() {
  for i in $(docker-machine ls --filter label=$1 --format {{.Name}})
  do 
    docker-machine stop $i
    docker-machine rm -f $i
  done  
}

ls () { 
  docker-machine ls --filter label=$1
  echo ""
}

ls "consul=agent"
ls "consul=server"

remove_DM_by_label "consul=agent"
remove_DM_by_label "consul=server"