#!/bin/bash

SCRIPT_ROOT="$(readlink -f $(dirname "${BASH_SOURCE[0]}"))"

OUTPUT_FILENAME=$(date -u +"%Y-%m-%d-%H-%M-%S")
OUTPUT_FILENAME="${SCRIPT_ROOT}/../data/debug/debug-${OUTPUT_FILENAME}.txt"

echo "Running debug"

echo "-- Debug Report --" > "${OUTPUT_FILENAME}"
timeout 30 date &>> "${OUTPUT_FILENAME}"
timeout 30 uptime -p &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "Firmware"

echo "-- Firmware --" &>> "${OUTPUT_FILENAME}"
timeout 30 vcgencmd version &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "Temperature"

echo "-- Temperature --" &>> "${OUTPUT_FILENAME}"
timeout 30 vcgencmd measure_temp &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "dmesg"

echo "-- dmesg --" &>> "${OUTPUT_FILENAME}"
timeout 30 dmesg &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "Throttling"

echo "-- Throttling --" &>> "${OUTPUT_FILENAME}"
timeout 30 vcgencmd get_throttled &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "Ping Cloudflare"

echo "-- Ping Cloudflare --" &>> "${OUTPUT_FILENAME}"
timeout 30 ping 1.1.1.1 -c 8 &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "Ping Google"

echo "-- Ping Google --" &>> "${OUTPUT_FILENAME}"
timeout 30 ping 8.8.8.8 -c 8 &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "Traceroute to Cloudflare"

echo "-- Traceroute to Cloudflare --" &>> "${OUTPUT_FILENAME}"
timeout 60 traceroute 1.1.1.1 &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "Traceroute to Google"

echo "-- Traceroute to Google --" &>> "${OUTPUT_FILENAME}"
timeout 60 traceroute 8.8.8.8 &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "Check DNS (sdsweather.com)"

echo "-- Check DNS (sdsweather.com) --" &>> "${OUTPUT_FILENAME}"
timeout 30 host sdsweather.com &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "Check DNS (google.com)"

echo "-- Check DNS (google.com) --" &>> "${OUTPUT_FILENAME}"
timeout 30 host google.com &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "wget sdsweather.com"

echo "-- wget sdsweather.com --" &>> "${OUTPUT_FILENAME}"
timeout 30 wget --server-response -qO /dev/null https://sdsweather.com &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"
echo "wget sdsweather.com"

echo "-- wget video1.radaromega.com --" &>> "${OUTPUT_FILENAME}"
timeout 30 wget --server-response -qO /dev/null https://video1.radaromega.com &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "route"

echo "-- route --" &>> "${OUTPUT_FILENAME}"
timeout 30 route &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "Ifconfig (all)"

echo "-- ifconfig -a --" &>> "${OUTPUT_FILENAME}"
timeout 30 ifconfig -a &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "Ethtool eth0"

echo "-- ethtool eth0 --" &>> "${OUTPUT_FILENAME}"
timeout 30 ethtool eth0 &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "Ethtool eth1"

echo "-- ethtool eth1 --" &>> "${OUTPUT_FILENAME}"
timeout 30 ethtool eth1 &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "Ethtool wlan0"

echo "-- ethtool wlan0 --" &>> "${OUTPUT_FILENAME}"
timeout 30 ethtool wlan0 &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "Iptables (all)"

echo "-- iptables --" &>> "${OUTPUT_FILENAME}"
timeout 30 iptables -L -v -n &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "Net cam container logs"

echo "-- net_cam --" &>> "${OUTPUT_FILENAME}"
timeout 30 docker logs --tail 500 net_cam &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "Usb cam container logs"

echo "-- usb_cam --" &>> "${OUTPUT_FILENAME}"
timeout 30 docker logs --tail 500 usb_cam &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "Free"

echo "-- free --" &>> "${OUTPUT_FILENAME}"
timeout 30 free &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "df -h"

echo "-- df -h --" &>> "${OUTPUT_FILENAME}"
timeout 30 df -h &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "df -i"

echo "-- df -i --" &>> "${OUTPUT_FILENAME}"
timeout 30 df -i &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "lsblk"

echo "-- lsblk --" &>> "${OUTPUT_FILENAME}"
timeout 30 lsblk &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"

echo "lsusb"

echo "-- lsusb --" &>> "${OUTPUT_FILENAME}"
timeout 30 lsusb &>> "${OUTPUT_FILENAME}"
echo &>> "${OUTPUT_FILENAME}"


