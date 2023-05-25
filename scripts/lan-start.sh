#!/bin/bash

WS_ROOT="$(readlink -f $(dirname "${BASH_SOURCE[0]}"))/.."

IFACE_WAN=eth0

for IFACE_LAN in $(ls /sys/class/net/); do
	if [[ "${IFACE_LAN}" != "eth"* ]] || [[ "${IFACE_LAN}" == "${IFACE_WAN}" ]]; then
		continue
	fi

	export NETWORK_BASE=$("${WS_ROOT}/scripts/lan-network-base.sh")
	export NETWORK_IP="${NETWORK_BASE}.1"
	export CIDR="${NETWORK_IP}/24"
	export NETWORK_RANGE="${NETWORK_BASE}.100,${NETWORK_BASE}.150"
	export DNS_SERVERS="1.1.1.1,8.8.8.8"
	export INTERFACE="${IFACE_LAN}"
	
	echo "Setting up interface: ${IFACE_LAN} (${CIDR})"

	ip link set dev $IFACE_LAN down
	ip address add "${CIDR}" dev $IFACE_LAN
	ip link set dev $IFACE_LAN up

	echo "Forward traffic from ${IFACE_WAN} to ${IFACE_LAN}..."
	iptables -A FORWARD -i $IFACE_WAN -o $IFACE_LAN -m state --state ESTABLISHED,RELATED -j ACCEPT
	iptables -A FORWARD -i $IFACE_LAN -o $IFACE_WAN -j ACCEPT
	iptables -t nat -A POSTROUTING -o $IFACE_WAN -j MASQUERADE

	echo
	echo "Starting lan container..."
	compose_files=("-f" "${WS_ROOT}/docker-compose.lan.yaml")
	if [[ -f "${WS_ROOT}/docker-compose.lan.dev.yaml" ]]; then
		compose_files+=( "--file" "${WS_ROOT}/docker-compose.lan.dev.yaml" )
	fi
	docker compose --project-name "lan-${IFACE_LAN}" "${compose_files[@]}" up -d
done
