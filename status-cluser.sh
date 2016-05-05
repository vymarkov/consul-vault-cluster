#! /bin/bash

. ./variables.sh

for i in $(eval echo {1..$CONSUL_CLUSTER_SIZE}) 
do
	dockerMachineName="consul-server-0$i"
	echo $dockerMachineName status: "$(docker-machine status $dockerMachineName)"
done

for i in $(eval echo {1..$CONSUL_AGENTS}) 
do
	dockerMachineName="consul-server-0$i"
	echo $dockerMachineName status: "$(docker-machine status $dockerMachineName)"
done