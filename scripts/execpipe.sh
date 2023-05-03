#!/bin/bash

# Must be ran as root
if [[ "$EUID" -ne 0 ]]; then
	echo_line "Please run as root"
	echo
	exit 1
fi

while true; do
    cmd=$(cat /tmp/cycloneport-execpipe)
    echo "Running: ${cmd}"
    eval "${cmd}"
    sleep 0.1
    echo
done