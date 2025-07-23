#!/bin/bash

CONFIG_FILE="net_config.conf"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file $CONFIG_FILE not found!"
    exit 1
fi

# Load configuration values
source "$CONFIG_FILE"

# Set hostname
if [ -n "$HOSTNAME" ]; then
    hostnamectl set-hostname "$HOSTNAME"
    echo "Hostname set to: $HOSTNAME"
fi

# Find the active interface (excluding loopback)
IFACE=$(nmcli device status | grep "connected" | grep -v "lo" | awk '{print $1}')
if [ -z "$IFACE" ]; then
    echo "No active network interface found!"
    exit 1
fi

# Convert netmask to CIDR format
function netmask_to_cidr() {
    local IFS=.
    local count=0
    for octet in $1; do
        case $octet in
            255) count=$((count+8));;
            254) count=$((count+7));;
            252) count=$((count+6));;
            248) count=$((count+5));;
            240) count=$((count+4));;
            224) count=$((count+3));;
            192) count=$((count+2));;
            128) count=$((count+1));;
            0) ;;
            *) echo "Invalid netmask: $1" && exit 1;;
        esac
    done
    echo "$count"
}

CIDR=$(netmask_to_cidr "$NETMASK")

# Configure network using nmcli
nmcli con mod "$IFACE" ipv4.addresses "$IPADDR/$CIDR"
nmcli con mod "$IFACE" ipv4.gateway "$GATEWAY"
nmcli con mod "$IFACE" ipv4.dns "$DNS"
nmcli con mod "$IFACE" ipv4.method manual
nmcli con up "$IFACE"

echo "Network configured on interface $IFACE: $IPADDR/$CIDR"

# Set timezone
if [ -n "$TIMEZONE" ]; then
    timedatectl set-timezone "$TIMEZONE"
    echo "Timezone set to: $TIMEZONE"
fi

echo "Configuration complete."
