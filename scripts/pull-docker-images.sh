#!/bin/bash

WS_ROOT="$(readlink -f $(dirname "${BASH_SOURCE[0]}"))/.."

# Start Wifi services
docker compose -f "${WS_ROOT}/docker-compose.wifi.yaml" pull

# start weatherstation system
docker compose -f "${WS_ROOT}/docker-compose.system.yaml" pull

# Start setup related services
docker compose -f "${WS_ROOT}/docker-compose.setup.yaml" pull

# Start Dozzle container
docker compose -f "${WS_ROOT}/docker-compose.dozzle.yaml" pull

# Start lan related services
docker compose -f "${WS_ROOT}/docker-compose.lan.yaml" pull

# Start video related services
docker compose -f "${WS_ROOT}/docker-compose.video.yaml" pull