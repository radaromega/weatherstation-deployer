#!/bin/bash
set -o xtrace

WPA_SUPPLICANT_FILE="/etc/wpa_supplicant/wpa_supplicant.conf"

# Check if a wpa_supplicant.conf file exists
if [[ ! -f "${WPA_SUPPLICANT_FILE}" ]]; then
    echo "wpa_supplicant.conf is missing. Creating a default conf file now."

    echo "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev" >> "${WPA_SUPPLICANT_FILE}"
    echo "update_config=1" >> "${WPA_SUPPLICANT_FILE}"
    echo "country=US" >> "${WPA_SUPPLICANT_FILE}"
fi

DESIRED_AP_IFACE="uap0"

wifi_adapters=$(iw dev | grep phy# | wc -l)

if [[ "${wifi_adapters}" -lt 2 ]]; then
    echo "2 or WiFi adapters NOT found"
    exit
fi

iw dev "${DESIRED_AP_IFACE}" del

# ifconfig

ap_exists=$(ifconfig | grep "${DESIRED_AP_IFACE}" | wc -l)

if [[ "${ap_exists}" -gt 0 ]]; then
    echo "${DESIRED_AP_IFACE} already setup"
    exit
fi

last_iface=$(iw dev | grep Interface | head -n 1 | awk '{ print $2 }')

echo "Setting up AP WiFi adapter: ${last_iface} to ${DESIRED_AP_IFACE}"

sudo ifconfig "${last_iface}" down

sudo ip link set "${last_iface}" name "${DESIRED_AP_IFACE}"

sudo ifconfig "${DESIRED_AP_IFACE}" up