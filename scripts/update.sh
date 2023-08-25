#!/usr/bin/env bash
set -euo pipefail

CYCLONEPORT_REPO="radaromega/weatherstation-deployer"
CYCLONEPORT_VERSION="latest"

NOW_ISO8601=$(date +"%Y-%m-%d-%H-%M-%S")

WS_ROOT="$(realpath $(readlink -f $(dirname "${BASH_SOURCE[0]}"))/..)"
WS_HOME="/home/$(stat -c '%U' "${WS_ROOT}")"
WS_BACKUP_ROOT="$(readlink -f $(dirname "${BASH_SOURCE[0]}"))/../../weatherstation-${NOW_ISO8601}"

TEMP_WS_PATH="/tmp/ws-${NOW_ISO8601}"

RUNNING_PATH="/tmp/.cycloneport-update"

INFO_PATH="${WS_ROOT}/info.json"

versionToInt () {
	echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }';
}

echo_line () {
	echo
	echo "$@"
}

echo_title() {
	echo
	cat << EOF
 _____            _                 ______          _   
/  __ \          | |                | ___ \        | |  
| /  \/_   _  ___| | ___  _ __   ___| |_/ /__  _ __| |_ 
| |   | | | |/ __| |/ _ \| '_ \ / _ \  __/ _ \| '__| __|
| \__/\ |_| | (__| | (_) | | | |  __/ | | (_) | |  | |_ 
 \____/\__, |\___|_|\___/|_| |_|\___\_|  \___/|_|   \__|
        __/ |                                           
       |___/                                            
EOF
    echo_line "---------------------- Updating -----------------------"
}

echo_done() {
	echo
	cat << EOF
oooooooooo.     .oooooo.   ooooo      ooo oooooooooooo 
\`888'   \`Y8b   d8P'  \`Y8b  \`888b.     \`8' \`888'     \`8 
 888      888 888      888  8 \`88b.    8   888         
 888      888 888      888  8   \`88b.  8   888oooo8    
 888      888 888      888  8     \`88b.8   888    "    
 888     d88' \`88b    d88'  8       \`888   888       o 
o888bood8P'    \`Y8bood8P'  o8o        \`8  o888ooooood8
EOF
	echo
}

get_version() {
	version="${CYCLONEPORT_VERSION}"
	if [[ "${version}" == "latest" ]]; then
		version=$(curl --silent "https://www.sdsweather.com/cycloneport/system/tags.php?repo=${CYCLONEPORT_REPO}" | jq --raw-output '.[-1].ref' | awk -F/ '{ print $3 }')
	fi
	echo "${version}"
}

download_weatherstation() {
	version="${1}"

	echo_line "Downloading version: ${version}"

	mkdir -p "${TEMP_WS_PATH}"

	curl --location "https://www.sdsweather.com/cycloneport/system/archive.php?repo=${CYCLONEPORT_REPO}&version=${version}" | tar --extract --gzip --strip-components=1 --directory="${TEMP_WS_PATH}"

	# Set correct permissions
	USER_GROUP=$(stat -c '%U:%G' "${WS_ROOT}")
	chown -R "${USER_GROUP}" "${TEMP_WS_PATH}"
}

if [[ -f "${RUNNING_PATH}" ]]; then
    echo "CyclonePort Update already running..."
    exit
fi

touch "${RUNNING_PATH}"

trap "rm -f ${RUNNING_PATH}" EXIT

# Must be run as root
if [[ "$EUID" -ne 0 ]]; then
	echo
	echo "Please run as root"
	echo
	exit 1
fi

echo_title

active_version=$(cat "${INFO_PATH}" | jq --raw-output '.version')

echo_line "Active version: ${active_version}"

echo_line "Fetching latest version..."

latest_version=$(get_version)

echo_line "Latest version: ${latest_version}"

if [[ "$(versionToInt "${latest_version}")" -le "$(versionToInt "${active_version}")" ]]; then
	echo_line "Latest version already installed. Aborting..."
	exit
fi

download_weatherstation "${latest_version}"

echo_line "Pulling latest Docker images"

"${TEMP_WS_PATH}/scripts/pull-docker-images.sh"

echo_line "Stopping all services"

"${WS_ROOT}/scripts/stop.sh"

echo_line "Backing everything up"

cp -a "${WS_ROOT}" "${WS_BACKUP_ROOT}"

echo_line "Overlaying new software"

rsync --archive \
	--verbose \
	"${TEMP_WS_PATH}/" \
	"${WS_ROOT}/"

echo_line "Starting all services"

"${WS_ROOT}/scripts/start.sh"

echo_line "Deleting update files"

rm -rf "${TEMP_WS_PATH}"
rm -rf "${WS_BACKUP_ROOT}"

# Check containers are actually running

running_containers=$(docker ps -q | wc -l)

if [[ "${running_containers}" -ge "8" ]]; then
	echo_line "Deleting old Docker images"

	docker rmi $(docker images -aq)
fi

echo_done