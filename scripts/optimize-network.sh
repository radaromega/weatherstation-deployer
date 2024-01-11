#!/bin/bash

# Disable power management for wireless interfaces
/sbin/iw wlan0 set power_save off >/dev/null 2>&1
/sbin/iw uap0 set power_save off >/dev/null 2>&1

# Adjust internal kernel parameters related to networking
sysctl --quiet net.core.rmem_max=16777216
sysctl --quiet net.core.wmem_max=16777216
sysctl --quiet net.core.rmem_default=16777216
sysctl --quiet net.core.wmem_default=16777216
sysctl --quiet net.ipv4.tcp_rmem="4096 87380 16777216"
sysctl --quiet net.ipv4.tcp_wmem="4096 87380 16777216"

sysctl --quiet net.ipv4.tcp_mem="1638400 1638400 1638400"

sysctl --quiet net.ipv4.tcp_sack=0
sysctl --quiet net.ipv4.tcp_dsack=0
sysctl --quiet net.ipv4.tcp_fack=0

sysctl --quiet net.ipv4.tcp_slow_start_after_idle=0

sysctl --quiet net.ipv4.udp_rmem_min=8192
sysctl --quiet net.ipv4.udp_wmem_min=8192