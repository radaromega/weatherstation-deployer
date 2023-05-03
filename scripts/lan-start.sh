#!/bin/bash

WS_ROOT="$(readlink -f $(dirname "${BASH_SOURCE[0]}"))/.."

export NETWORK_BASE=$("${WS_ROOT}/scripts/lan-network-base.sh")
export NETWORK_IP="${NETWORK_BASE}.1"

echo "Setting up interfaces ${NETWORK_IP}..."

# Interfaces
IFACE_WAN=eth0
IFACE_LAN=eth1
CIDR="${NETWORK_IP}/24"

echo "Setup ${IFACE_LAN} interface..."
ip link set dev $IFACE_LAN down
ip address add "${CIDR}" dev $IFACE_LAN
ip link set dev $IFACE_LAN up

echo "Forward traffic from ${IFACE_WAN} to ${IFACE_LAN}..."
iptables -A FORWARD -i $IFACE_WAN -o $IFACE_LAN -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i $IFACE_LAN -o $IFACE_WAN -j ACCEPT
iptables -t nat -A POSTROUTING -o $IFACE_WAN -j MASQUERADE

export NETWORK_RANGE="${NETWORK_BASE}.100,${NETWORK_BASE}.150"
export DNS_SERVERS="1.1.1.1,8.8.8.8"
export INTERFACE="${IFACE_LAN}"

echo
echo "Starting lan containers..."
docker compose -f "${WS_ROOT}/docker-compose.lan.yaml" up -d