#!/bin/bash

export WS_ROOT="$(readlink -f $(dirname "${BASH_SOURCE[0]}"))/.."

# Must be run as root
if [[ "$EUID" -ne 0 ]]; then
	echo
	echo "Please run as root"
	echo
	exit 1
fi

dotenv_path="${WS_ROOT}/.env"
if ! [[ -f "${dotenv_path}" ]]; then
	touch "${dotenv_path}"
fi

execpipe_path="/tmp/cycloneport-execpipe"
if ! [[ -p "${execpipe_path}" ]]; then
	mkfifo "${execpipe_path}"
fi

# Run execpipe
screen -S execpipe -X quit || true
screen -dmS execpipe "${WS_ROOT}/scripts/execpipe.sh"

# Setup AP
"${WS_ROOT}/scripts/setup-ap.sh"

# Setup wlan0
nmcli dev set wlan0 managed no
ifconfig wlan0 down && ifconfig wlan0 up
systemctl start dhcpcd

# Start Wifi services
compose_files=("-f" "${WS_ROOT}/docker-compose.wifi.yaml")
if [[ -f "${WS_ROOT}/docker-compose.wifi.dev.yaml" ]]; then
	compose_files+=( "--file" "${WS_ROOT}/docker-compose.wifi.dev.yaml" )
fi
docker compose "${compose_files[@]}" up -d

"${WS_ROOT}/scripts/optimize-network.sh"

ifconfig wlan0 down && ifconfig wlan0 up

# start weatherstation system
compose_files=("-f" "${WS_ROOT}/docker-compose.system.yaml")
if [[ -f "${WS_ROOT}/docker-compose.system.dev.yaml" ]]; then
	compose_files+=( "--file" "${WS_ROOT}/docker-compose.system.dev.yaml" )
fi
docker compose "${compose_files[@]}" up -d

# Start setup related services
compose_files=("-f" "${WS_ROOT}/docker-compose.setup.yaml")
if [[ -f "${WS_ROOT}/docker-compose.setup.dev.yaml" ]]; then
	compose_files+=( "--file" "${WS_ROOT}/docker-compose.setup.dev.yaml" )
fi
docker compose "${compose_files[@]}" up -d

# Start Dozzle container
docker compose -f "${WS_ROOT}/docker-compose.dozzle.yaml" up -d

# Start lan related services
screen -dmS lan "${WS_ROOT}/scripts/lan-start.sh"

# Start video related services
compose_files=("-f" "${WS_ROOT}/docker-compose.video.yaml")
if [[ -f "${WS_ROOT}/docker-compose.video.dev.yaml" ]]; then
	compose_files+=( "--file" "${WS_ROOT}/docker-compose.video.dev.yaml" )
fi
docker compose "${compose_files[@]}" up -d
