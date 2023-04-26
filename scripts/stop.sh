#!/bin/bash

WS_ROOT="$(readlink -f $(dirname "${BASH_SOURCE[0]}"))/.."

docker compose -f "${WS_ROOT}/docker-compose.system.yaml" down

# Stop setup related services
docker compose -f "${WS_ROOT}/docker-compose.setup.yaml" down

# Stop Dozzle container
docker compose -f "${WS_ROOT}/docker-compose.dozzle.yaml" down

# Stop LAN container
# docker compose -f "${WS_ROOT}/docker-compose.lan.yaml" down

# Stop video related services
docker compose -f "${WS_ROOT}/docker-compose.video.yaml" down