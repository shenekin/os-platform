#!/bin/bash

CONFIG_FILE="net_config.conf"

# Check if configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file $CONFIG_FILE not found!"
    exit 1
fi

# Load configuration variables
source "$CONFIG_FILE"

# Set hostname
if [ -n "$HOSTNAME" ]; then
    echo "$HOSTNAME" > /etc/hostname
    hostnamectl set-hostname "$HOSTNAME"
    echo "127.0.1.1 $HOSTNAME" >> /etc/hosts
    echo "Hostname set to: $HOSTNAME"
fi

# Detect primary network interface (excluding loopback)
IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v 'lo' | head -n 1)
if [ -z "$IFACE" ]; then
    echo "No valid network interface found!"
    exit 1
fi

# Convert netmask to CIDR prefix using ipcalc
CIDR=$(ipcalc -p "$IPADDR" "$NETMASK" | awk -F= '{print $2}')

# Generate Netplan configuration file
NETPLAN_FILE="/etc/netplan/01-netcfg.yaml"
cat > "$NETPLAN_FILE" <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $IFACE:
      dhcp4: no
      addresses: [$IPADDR/$CIDR]
      gateway4: $GATEWAY
      nameservers:
        addresses: [$DNS]
EOF

# Apply the Netplan changes
netplan apply
echo "Network configuration applied: $IFACE -> $IPADDR/$CIDR"

# Set system timezone
if [ -n "$TIMEZONE" ]; then
    timedatectl set-timezone "$TIMEZONE"
    echo "Timezone set to: $TIMEZONE"
fi

echo "All configurations have been applied successfully."