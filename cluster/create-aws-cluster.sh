#! /bin/bash

terraform plan $ROOT/terraform/consul/aws/cluster
terraform apply $ROOT/terraform/consul/aws/cluster

$ROOT/docker-machine/provision-cluster.sh