#!/bin/bash

export WS_ROOT="$(realpath $(readlink -f $(dirname "${BASH_SOURCE[0]}"))/..)"
export WS_HOME="/home/$(stat -c '%U' "${WS_ROOT}")"

# Must be run as root
if [[ "$EUID" -ne 0 ]]; then
	echo
	echo "Please run as root"
	echo
	exit 1
fi

# Stop all containers
"${WS_ROOT}/scripts/stop.sh"

# Patch to ensure Docker daemon config is set
docker_config_path="/etc/docker/daemon.json"
if ! [[ -f "${docker_config_path}" ]]; then
	echo "Writing Docker default configuration"
	
	echo '{"log-driver": "json-file", "log-opts": {"max-size": "50m", "max-file": "1"}}' > "${docker_config_path}"
	systemctl restart docker
fi

# Patch to ensure dhcpcd does not manage eth0
dhcpcd_config_path="/etc/dhcpcd.conf"

DENY_ETH0="denyinterfaces eth0"

if grep -q "$DENY_ETH0" "$dhcpcd_config_path" ; then
	echo "Deny interface (eth0) is already set"
else
	echo "Setting denyinterface: ${DENY_ETH0}"
	
	echo -en '\n' >> $dhcpcd_config_path
	echo "${DENY_ETH0}" >> $dhcpcd_config_path

	systemctl restart dhcpcd
fi

# Patch to ensure 'rock' user is disabled
rock_passwd_expired=$(chage -l rock | grep "Account expires" | awk -F':' '{print $2}')
if [[ "${rock_passwd_expired}" == *"never"* ]]; then
	echo "Expiring 'rock' user"
	usermod --expiredate 1 rock
fi

dotenv_path="${WS_ROOT}/.env"
if ! [[ -f "${dotenv_path}" ]]; then
	touch "${dotenv_path}"
fi

# Run execpipe
screen -S execpipe -X quit || true
execpipe_path="/tmp/cycloneport-execpipe"
rm -rf "${execpipe_path}"
mkfifo "${execpipe_path}"
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
docker compose "${compose_files[@]}" up -d &

# Start setup related services
compose_files=("-f" "${WS_ROOT}/docker-compose.setup.yaml")
if [[ -f "${WS_ROOT}/docker-compose.setup.dev.yaml" ]]; then
	compose_files+=( "--file" "${WS_ROOT}/docker-compose.setup.dev.yaml" )
fi
docker compose "${compose_files[@]}" up -d &

# Start Dozzle container
docker compose -f "${WS_ROOT}/docker-compose.dozzle.yaml" up -d &

# Start lan related services
screen -dmS lan "${WS_ROOT}/scripts/lan-start.sh" &

# Start video related services
compose_files=("-f" "${WS_ROOT}/docker-compose.video.yaml")
if [[ -f "${WS_ROOT}/docker-compose.video.dev.yaml" ]]; then
	compose_files+=( "--file" "${WS_ROOT}/docker-compose.video.dev.yaml" )
fi
docker compose "${compose_files[@]}" up -d &

wait