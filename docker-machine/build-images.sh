#! /bin/bash

set -e

. ./variables.sh

#### Functions

DIND=${DIND:-"true"}
DOCKER_MACHINE_NAME=${DOCKER_MACHINE_NAME:-"consul-vault-cluster"} 

tfstate="$ROOT/terraform/consul/aws/terraform.tfstate"
CONSUL_IMAGE="$(cat $tfstate | jq -rM '.modules[0].outputs.consul_repository_url' | cut -c 9-)"
VAULT_IMAGE="$(cat $tfstate | jq -rM '.modules[0].outputs.vault_repository_url' | cut -c 9-)"

function build_image() {
  image_name=$1
  path=$2
  tag="$image_name-demo"
  
  docker build -t $tag $path
  docker tag $tag:latest $image_name:latest
  
  docker push $image_name:latest
}

function build_images() {
  dockerVer="$(docker version --format {{.Server.Version}})" 

  if [ "$dockerVer" != "$DOCKER_VERSION" ]; then
    eval $(docker-machine env consul-vault-cluster)
  fi

  $(aws ecr get-login)
  
  build_image $CONSUL_IMAGE "$ROOT/consul/0.6"
  build_image $VAULT_IMAGE "$ROOT/vault/0.5"
}

build_images