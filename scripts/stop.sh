#!/bin/bash

export WS_ROOT="$(realpath $(readlink -f $(dirname "${BASH_SOURCE[0]}"))/..)"
export WS_HOME="/home/$(stat -c '%U' "${WS_ROOT}")"

docker compose -f "${WS_ROOT}/docker-compose.system.yaml" down &

# Stop setup related services
docker compose -f "${WS_ROOT}/docker-compose.setup.yaml" down &

# Stop Dozzle container
docker compose -f "${WS_ROOT}/docker-compose.dozzle.yaml" down &

# Stop LAN container
lan_container_ids=$(docker ps -f name=lan- -q)
docker stop $lan_container_ids && docker rm $lan_container_ids &

# Stop video related services
docker compose -f "${WS_ROOT}/docker-compose.video.yaml" down &

wait