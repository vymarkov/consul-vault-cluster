#! /bin/bash

# Pay attention, there we use own image* as a base Docker image for running Consul 
# in the Docker Container, therefore we need to build this image
# In several Docker Compose files we use an $CONSUL_IMAGE environment variable 
# for development purposes, therefore we have the ability to swith between other images
# like consul:v0.6.4 (the official Consul docker image) or progrium/consul

# * - actually, it's an official docker images without using gosu in a docker container
# gosu switches to the consul user and run command on behalf of this user
# and unfortunately we can't use a mounted docker volume from host machine  
 
docker build -t consul-dev -f "$ROOT/consul/0.6/Dockerfile" "$ROOT/consul/0.6"
docker build -t vault-dev -f "$ROOT/vault/0.5/Dockerfile" "$ROOT/vault/0.5"