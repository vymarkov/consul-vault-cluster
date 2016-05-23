#! /bin/bash


function removeDms() {
  state="/tmp/.machines.json"
  tfstate="$ROOT/terraform/consul/aws/terraform.tfstate"

  cat $tfstate | jq '.modules[0].resources | to_entries | map(select(.value.type == "aws_instance")) | map(.value.primary.attributes)' > $state
  servers="$(cat $state | jq -rM 'map(.public_ip) | join(" ")')"
  
  for ip in $servers
  do 
    servername="$(cat $state | jq --arg _ip $ip -rM 'map(select(.public_ip == $_ip)) | .[0] | .["tags.Name"]')"
    if [ $servername != "null" ]; then
      docker-machine rm -f $servername
    fi
  done  
}

function removeAwsInfra() {
  terraform destroy -force -state="$ROOT/terraform/consul/aws/terraform.tfstate" "$ROOT/terraform/consul/aws/cluster"
}

function main() {
  removeAwsInfra
  removeDms
}

main