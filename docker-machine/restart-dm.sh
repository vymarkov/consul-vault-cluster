#! /bin/bash

set -e

for dm in $(docker-machine ls --filter driver=virtualbox --filter label=project_name=phoenix --format {{.Name}}); do
   docker-machine restart $dm
done 
