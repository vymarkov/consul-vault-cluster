#!/bin/bash

trap "exit 143" SIGTERM SIGINT

confd -backend env -onetime
vault $@ &

wait ${!}