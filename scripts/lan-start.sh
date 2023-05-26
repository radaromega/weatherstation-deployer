#!/bin/bash

WS_ROOT="$(readlink -f $(dirname "${BASH_SOURCE[0]}"))/.."

IFACE_WAN=eth0

for IFACE_LAN in $(ls /sys/class/net/); do
	if [[ "${IFACE_LAN}" != "eth"* ]] || [[ "${IFACE_LAN}" == "${IFACE_WAN}" ]]; then
		continue
	fi

	# Check if interface already has an IP
	if_ips=$(ip -f inet addr show "${IFACE_LAN}" | sed -En -e 's/.*inet ([0-9.]+).*/\1/p')

	setup_if=0

	if [[ "${if_ips}" == *"192.168."* ]]; then
		echo "Interface already setup: ${IFACE_LAN}"

		if_ip=$(echo "${if_ips}" | grep "192.168.")

		first_octet=$(echo "${if_ip}" | awk -F. '{ print $1 }')
        second_octet=$(echo "${if_ip}" | awk -F. '{ print $2 }')
        third_octet=$(echo "${if_ip}" | awk -F. '{ print $3 }')

		NETWORK_BASE="${first_octet}.${second_octet}.${third_octet}"
	else
		NETWORK_BASE=$("${WS_ROOT}/scripts/lan-network-base.sh")

		setup_if=1
	fi
	
	export NETWORK_IP="${NETWORK_BASE}.1"
	CIDR="${NETWORK_IP}/24"
	export NETWORK_RANGE="${NETWORK_BASE}.100,${NETWORK_BASE}.150"
	export DNS_SERVERS="1.1.1.1,8.8.8.8"
	export INTERFACE="${IFACE_LAN}"

	if [[ "${setup_if}" == "1" ]]; then
		echo "Setting up interface: ${IFACE_LAN} (${CIDR})"

		ip link set dev $IFACE_LAN down
		ip address add "${CIDR}" dev $IFACE_LAN
		ip link set dev $IFACE_LAN up

		echo "Forward traffic from ${IFACE_WAN} to ${IFACE_LAN}..."
		iptables -A FORWARD -i $IFACE_WAN -o $IFACE_LAN -m state --state ESTABLISHED,RELATED -j ACCEPT
		iptables -A FORWARD -i $IFACE_LAN -o $IFACE_WAN -j ACCEPT
		iptables -t nat -A POSTROUTING -o $IFACE_WAN -j MASQUERADE
	fi

	echo
	echo "Starting lan container..."
	compose_files=("-f" "${WS_ROOT}/docker-compose.lan.yaml")
	if [[ -f "${WS_ROOT}/docker-compose.lan.dev.yaml" ]]; then
		compose_files+=( "--file" "${WS_ROOT}/docker-compose.lan.dev.yaml" )
	fi
	docker compose --project-name "lan-${IFACE_LAN}" "${compose_files[@]}" up -d
done
