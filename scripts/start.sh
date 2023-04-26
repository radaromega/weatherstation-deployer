#!/bin/bash

WS_ROOT="$(readlink -f $(dirname "${BASH_SOURCE[0]}"))/.."

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

# Turn on orange to say it's booted
# python3 ./python/pixel.py 0.1 255 94 19

# Setup AP
"${WS_ROOT}/scripts/setup-ap.sh"

# Setup wlan0
nmcli dev set wlan0 managed no
ifconfig wlan0 && ifconfig wlan0 down && ifconfig wlan0 up
systemctl start dhcpcd

# Start Wifi services
docker compose -f "${WS_ROOT}/docker-compose.wifi.yaml" up -d

"${WS_ROOT}/scripts/optimize-network.sh"

docker compose -f "${WS_ROOT}/docker-compose.system.yaml" up -d

# Start setup related services
docker compose -f "${WS_ROOT}/docker-compose.setup.yaml" up -d

# Start Dozzle container
docker compose -f "${WS_ROOT}/docker-compose.dozzle.yaml" up -d

# Start signal K related services
# /sbin/ip link set can0 up type can bitrate 250000
# service signalk restart

# Start lan related services
screen -dmS lan "${WS_ROOT}/lan/scripts/run.sh"

# Start video related services
docker compose -f "${WS_ROOT}/docker-compose.video.yaml" up -d