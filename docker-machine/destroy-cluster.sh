#! /bin/bash

set -e

machines=$(docker-machine ls --filter driver=virtualbox --filter label=project_name=phoenix --format {{.Name}})

for dm in $machines; 
do
   docker-machine rm -f $dm
done 