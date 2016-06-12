#! /bin/bash

 export AWS_ACCESS_KEY_ID=$(terraform output -state=$ROOT/terraform/consul/aws/iam/terraform.tfstate consul_access_key_id)
 export AWS_SECRET_ACCESS_KEY=$(terraform output -state=$ROOT/terraform/consul/aws/iam/terraform.tfstate consul_secret_access_key)