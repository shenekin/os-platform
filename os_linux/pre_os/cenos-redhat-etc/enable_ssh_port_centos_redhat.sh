#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run the script as root!"
    exit 1
fi

# Enable port 22 (SSH)
echo "Enabling port 22 (SSH)..."

# Open port 22
sudo firewall-cmd --zone=public --add-port=22/tcp --permanent

# Reload firewall rules
sudo firewall-cmd --reload

# Verify if port 22 is open
if sudo firewall-cmd --list-ports | grep -q "22/tcp"; then
    echo "Port 22 has been successfully enabled!"
else
    echo "Failed to enable port 22!"
    exit 1
fi
