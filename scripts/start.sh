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

# Stop everything
"${WS_ROOT}/scripts/stop.sh"

# Create empty .env if it does not exist
dotenv_path="${WS_ROOT}/.env"
if ! [[ -f "${dotenv_path}" ]]; then
	touch "${dotenv_path}"
fi

# Source the .env file
if [[ -f "${dotenv_path}" ]]; then
	set -o allexport
	source "${dotenv_path}" set
	set +o allexport
fi

# Patch to ensure Docker daemon config is set
docker_config_path="/etc/docker/daemon.json"
if ! [[ -f "${docker_config_path}" ]]; then
	echo "Writing Docker default configuration"
	
	echo '{"log-driver": "json-file", "log-opts": {"max-size": "50m", "max-file": "1"}}' > "${docker_config_path}"
	systemctl restart docker
fi

# Patch to ensure 'rock' user is disabled
rock_passwd_expired=$(chage -l rock | grep "Account expires" | awk -F':' '{print $2}')
if [[ "${rock_passwd_expired}" == *"never"* ]]; then
	echo "Expiring 'rock' user"
	usermod --expiredate 1 rock
fi

# Patch to remove Tailscale
if [[ -z ${TAILSCALE+x} ]]; then
	if [[ -x "$(command -v tailscale)" ]]; then
		echo "Tailscale is installed. Logging out..."
		tailscale logout || true
	fi
fi

# Patch to add/remove denyinterface to dhcpcd config
dhcpcd_search_string="denyinterfaces eth0"
dhcpcd_filename="/etc/dhcpcd.conf"

if grep -q "ip_address=" "$dhcpcd_filename"; then
	# Static IP config
	if grep -q "$dhcpcd_search_string" "$dhcpcd_filename"; then
		echo "Removing denyinterfaces eth0 because we're using Static IP"
		sed -i "/$dhcpcd_search_string/d" "$dhcpcd_filename"
		service dhcpcd restart
	fi
else
	# DHCP config
	if ! grep -q "$dhcpcd_search_string" "$dhcpcd_filename"; then
		echo "Adding denyinterfaces eth0 because we're using DHCP"
		echo "${dhcpcd_search_string}" >> "$dhcpcd_filename"
		service dhcpcd restart
	fi
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