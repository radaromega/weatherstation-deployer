#!/bin/bash

desired_ip=(192 168 12)

while true; do
    # Get line where Genmask = 0.0.0.0
    main_route=$(route | awk 'match($3, "0.0.0.0")')
    main_int=$(echo "${main_route}" | awk '{ print $8 }')

    if ! [[ -z "${main_int}" ]]; then
        # echo "Interface: ${main_int}"

        main_int_ip=$(ip -f inet addr show "${main_int}" | sed -En -e 's/.*inet ([0-9.]+).*/\1/p')

        # echo "IP: ${main_int_ip}"

        first_octet=$(echo "${main_int_ip}" | awk -F. '{ print $1 }')
        second_octet=$(echo "${main_int_ip}" | awk -F. '{ print $2 }')
        third_octet=$(echo "${main_int_ip}" | awk -F. '{ print $3 }')
        # echo "${first_octet} ${second_octet} ${third_octet}"

        if [[ "${first_octet}" != "${desired_ip[0]}" ]] && [[ "${second_octet}" != "${desired_ip[1]}" ]]; then
            echo "${desired_ip[0]}.${desired_ip[1]}.${desired_ip[2]}"
            exit
        fi

        desired_third_octet="${desired_ip[2]}"

        # Check if third octet is 12
        if [[ "${desired_third_octet}" == "${third_octet}" ]]; then
            ((desired_third_octet=desired_third_octet+1))
        fi

        # 27 is reserved for the CyclonePort Wifi (config) network
        if [[ "${desired_third_octet}" == "27" ]]; then
            ((desired_third_octet=desired_third_octet+1))
        fi

        ((desired_third_octet=desired_third_octet%256))

        echo "${desired_ip[0]}.${desired_ip[1]}.${desired_third_octet}"
        exit
    fi

    sleep 1
done

