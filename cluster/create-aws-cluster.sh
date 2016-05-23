#! /bin/bash

pwd=$PWD

cd "$ROOT/docker-machine"

terraform plan -state="$ROOT/terraform/consul/aws/terraform.tfstate" "$ROOT/terraform/consul/aws/cluster"
terraform apply -state="$ROOT/terraform/consul/aws/terraform.tfstate" "$ROOT/terraform/consul/aws/cluster"

./provision-dms.sh
./build-images.sh
./provision-cluster.sh
./init-vault-cluster.sh

terraform output -state="$ROOT/terraform/consul/aws/terraform.tfstate"

cd $pwd