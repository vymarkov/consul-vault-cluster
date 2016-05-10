#!/bin/bash

# WARNING
# Please note, that script generate sensitive data 
# thus it should not be logged to any log system 

vault_addr=$1
root_token=$2
app_id=${APP_ID:-"$(uuid -v 4)"}
user_id=${USER_ID:-"$(uuid -v 4)"}
policy=${POLICY:-"root"}

echo Adding a new app...
resp=$(http -v --body $vault_addr/v1/auth/app-id/map/app-id/$app_id "X-Vault-Token: $root_token" value=$policy)
echo App was sucessfully added.

echo Adding a new user...
resp=$(http -v --body $vault_addr/v1/auth/app-id/map/user-id/$user_id "X-Vault-Token: $root_token" value=$app_id)
echo User was sucessfully added.

echo "Trying to log in..."
resp=$(http -v --body $vault_addr/v1/auth/app-id/login app_id=$app_id user_id=$user_id)
token="$(echo $resp | jq -r -M .auth.client_token)"

echo "Your App Id: $app_id"
echo "Your User Id: $user_id"
echo "Youd App token: $token"