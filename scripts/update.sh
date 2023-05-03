#!/usr/bin/env bash
set -euo pipefail

CYCLONEPORT_REPO="radaromega/weatherstation-deployer"
CYCLONEPORT_VERSION="latest"

NOW_ISO8601=$(date +"%Y-%m-%d-%H-%M-%S")

WS_ROOT="$(readlink -f $(dirname "${BASH_SOURCE[0]}"))/.."
WS_BACKUP_ROOT="$(readlink -f $(dirname "${BASH_SOURCE[0]}"))/../../weatherstation-${NOW_ISO8601}"

UPDATE_PATH="/tmp/ws-${NOW_ISO8601}"

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
		version=$(curl --silent "https://api.github.com/repos/${CYCLONEPORT_REPO}/git/refs/tags" | jq --raw-output '.[0].ref' | awk -F/ '{ print $3 }')
	fi
	echo "${version}"
}

download_weatherstation() {
	version="${1}"

	echo_line "Downloading version: ${version}"

	mkdir -p "${UPDATE_PATH}"

	curl --location "https://github.com/${CYCLONEPORT_REPO}/archive/refs/tags/${version}.tar.gz" | tar --extract --gzip --strip-components=1 --directory="${UPDATE_PATH}"

	# Set correct permissions
	USER_GROUP=$(stat -c '%U:%G' "${WS_ROOT}")
	chown -R "${USER_GROUP}" "${UPDATE_PATH}"
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

echo_line "Stopping all services"

"${WS_ROOT}/scripts/stop.sh"

echo_line "Backing everything up"

cp -a "${WS_ROOT}" "${WS_BACKUP_ROOT}"

download_weatherstation "${latest_version}"

echo_line "Overlaying new software"

rsync --archive \
	--verbose \
	"${UPDATE_PATH}/" \
	"${WS_ROOT}/"

echo_line "Starting all services"

"${WS_ROOT}/scripts/start.sh"

echo_line "Deleting update files"

rm -rf "${UPDATE_PATH}"
rm -rf "${WS_BACKUP_ROOT}"

echo_done