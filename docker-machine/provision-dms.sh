state="/tmp/.machines.json"
tfstate="$ROOT/terraform/consul/aws/terraform.tfstate"

cat $tfstate | jq '.modules[0].resources | to_entries | map(select(.value.type == "aws_instance")) | map(.value.primary.attributes)' > $state

MACHINE_DRIVER=generic
ssh_port=${GENERIC_SSH_PORT:-22}
ssh_user=${GENERIC_SSH_USER:-"ubuntu"}
ssh_key=$TF_VAR_consul_key_path

ips="$(cat $state | jq -Mr 'map(.public_ip) | join(" ")')"
for ip in $ips; do
  dmname="$(cat $state | jq --arg ip $ip -rM 'map(select(.public_ip == $ip)) | .[0] | .["tags.Name"]')"
  exists="$(docker-machine ls --filter name=$dmname --format {{.Name}})"
  
  # remove machine with force flag 
  # docker-machine rm -f $dmname
  
  if [ -z "$exists" ]; then
    docker-machine create --driver $MACHINE_DRIVER --engine-label consul_role=server --engine-label service=consul --generic-ip-address $ip --generic-ssh-key $ssh_key --generic-ssh-port $ssh_port --generic-ssh-user $ssh_user $dmname
  else
    echo "Docker Machine with $dmname name already exists." 
  fi
done