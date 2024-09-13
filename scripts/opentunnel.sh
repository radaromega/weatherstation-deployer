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

DOTENV_FILE="${WS_ROOT}/.env"

if [[ -f "${DOTENV_FILE}" ]]; then
    source "${DOTENV_FILE}"
fi

# TODO: Point this at production
API_ENDPOINT_PULL_COMMAND="http://sdsweather.test/cycloneport/iot/get_port.php?uuid=$DEVICE_ID";
response=$(curl --silent --max-time 30 "${API_ENDPOINT_PULL_COMMAND}");
REMOTE_PORT=$(echo "${response}" | jq --raw-output '.port')
echo "Remote port: ${REMOTE_PORT}"
# TODO: Point this to a subdomain that we have control over
TUNNEL_IP=18.236.72.240

LOCAL_PORT=22

TUNNEL_USER=tunnel-user

cat authorized_keys > /home/pi/.ssh/authorized_keys

apt-get install autossh

autossh -M 20000 -f -N -R $REMOTE_PORT:localhost:$LOCAL_PORT $TUNNEL_USER@$TUNNEL_IP -i /home/pi/.ssh/id_rsa


