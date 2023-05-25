#!/bin/bash

desired_ip=(192 168 12)

while true; do
    # Get line where Genmask = 0.0.0.0
    main_route=$(route | awk 'match($3, "0.0.0.0")')
    main_if=$(echo "${main_route}" | awk '{ print $8 }')

    if ! [[ -z "${main_if}" ]]; then
        break
    fi

    sleep 1
done

desired_third_octet="${desired_ip[2]}"

network_base="${desired_ip[0]}.${desired_ip[1]}.${desired_third_octet}"

# While the current base is found in the list of existing
# IP addresses that the system already has
while hostname --all-ip-addresses | grep --quiet "${network_base}."; do
    # Increment third octet by 1
    ((desired_third_octet=desired_third_octet+1))

    # 27 is reserved for the CyclonePort Wifi (config) network
    if [[ "${desired_third_octet}" == "27" ]]; then
        ((desired_third_octet=desired_third_octet+1))
    fi

    ((desired_third_octet=desired_third_octet%256))

    network_base="${desired_ip[0]}.${desired_ip[1]}.${desired_third_octet}"
done

echo "${network_base}"
