#! /bin/bash

shutdownServer() {
  echo "trying to shutdown the server..."
  
  npm stop
  exit 143
}
trap "shutdownServer" SIGTERM SIGINT

echo "Server listening on 3000 port..."

confd -interval=5 -log-level=debug -backend vault -node $VAULT_ADDR -auth-type app-id -app-id $VAULT_APP_ID -user-id $VAULT_USER_ID &

wait ${!}