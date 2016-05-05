#! /bin/bash

. ./variables.sh

for i in $(eval echo {1..$CONSUL_CLUSTER_SIZE}) 
do
	docker-machine stop "consul-server-0$i"
done

for i in $(eval echo {1..$CONSUL_AGENTS}) 
do
	docker-machine stop "consul-agent-0$i"
done