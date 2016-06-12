#! /bin/bash

sandbox="$(docker ps -f label=sandbox --format {{.ID}})"
cids="$(docker ps -q)"

for cid in $cids; do
  if [ "$cid" != "$sandbox" ]; then
    docker kill $cid
    docker rm -f $cid
  fi
done

docker network rm vault-lb-tier