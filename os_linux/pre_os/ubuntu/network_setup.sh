#!/bin/bash

# Ubuntu 24 Network and Hostname Configuration Script
# Works with network_config.conf

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/network_config.conf"

# Log functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Check if running with root privileges
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script requires root privileges to run"
        echo "Please use: sudo $0"
        exit 1
    fi
}

# Load configuration file
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Configuration file does not exist: $CONFIG_FILE"
        echo "Please create network_config.conf in the same directory as this script"
        exit 1
    fi
    
    log_info "Loading configuration file: $CONFIG_FILE"
    . "$CONFIG_FILE"
    
    # Set defaults if not defined
    HOSTNAME="${HOSTNAME:-myserver01}"
    INTERFACE="${INTERFACE:-eth0}"
    IP_ADDRESS="${IP_ADDRESS:-192.168.1.100}"
    NETMASK="${NETMASK:-255.255.255.0}"
    GATEWAY="${GATEWAY:-192.168.1.1}"
    DNS_SERVERS="${DNS_SERVERS:-8.8.8.8}"
    UPDATE_HOSTS="${UPDATE_HOSTS:-no}"
    USE_NETPLAN="${USE_NETPLAN:-yes}"
    
    # Validate required parameters
    if [ -z "$HOSTNAME" ]; then
        log_error "Hostname not set"
        exit 1
    fi
    
    if [ "$UPDATE_HOSTS" = "yes" ] && [ "${#HOSTS_ENTRIES[@]}" -eq 0 ]; then
        log_warn "UPDATE_HOSTS=yes but HOSTS_ENTRIES is empty"
    fi
}

# Get current system information
get_current_info() {
    CURRENT_HOSTNAME=$(hostnamectl status --static 2>/dev/null || hostname)
    CURRENT_INTERFACES=$(ip -br addr show 2>/dev/null | grep -v "lo" | awk '{print $1}' | tr '\n' ' ')
    
    # Try to get current IP information for the specified interface
    if ip link show "$INTERFACE" >/dev/null 2>&1; then
        CURRENT_IP=$(ip -4 addr show "$INTERFACE" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
        CURRENT_CIDR=$(ip -4 addr show "$INTERFACE" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+' | head -1 | cut -d'/' -f2)
        CURRENT_GATEWAY=$(ip route show default 2>/dev/null | grep -oP '(?<=via\s)\d+(\.\d+){3}' | head -1)
        
        if command -v resolvectl >/dev/null 2>&1; then
            CURRENT_DNS=$(resolvectl dns 2>/dev/null | grep -v "Global\|Link" | awk '{print $NF}' | tr '\n' ' ' | sed 's/ $//')
        fi
        
        if [ -z "$CURRENT_DNS" ]; then
            CURRENT_DNS=$(grep "nameserver" /etc/resolv.conf 2>/dev/null | awk '{print $2}' | tr '\n' ' ')
        fi
        
        if [ -z "$CURRENT_DNS" ]; then
            CURRENT_DNS="Not configured"
        fi
        
        if [ -z "$CURRENT_IP" ]; then
            CURRENT_IP="No IP assigned"
        fi
        if [ -z "$CURRENT_GATEWAY" ]; then
            CURRENT_GATEWAY="No gateway configured"
        fi
    else
        CURRENT_IP="Interface not found"
        CURRENT_CIDR="N/A"
        CURRENT_GATEWAY="N/A"
        CURRENT_DNS="N/A"
    fi
}

# Display current configuration
show_current_config() {
    echo ""
    echo -e "${BOLD}${CYAN}========================================${NC}"
    echo -e "${BOLD}${CYAN}     CURRENT SYSTEM CONFIGURATION       ${NC}"
    echo -e "${BOLD}${CYAN}========================================${NC}"
    echo ""
    echo -e "  ${BOLD}Hostname:${NC}        ${GREEN}${CURRENT_HOSTNAME}${NC}"
    echo -e "  ${BOLD}Available NICs:${NC}  ${YELLOW}${CURRENT_INTERFACES}${NC}"
    echo ""
    
    if ip link show "$INTERFACE" >/dev/null 2>&1; then
        echo -e "  ${BOLD}Target Interface:${NC} ${YELLOW}${INTERFACE}${NC}"
        echo -e "  ${BOLD}Current IP:${NC}       ${GREEN}${CURRENT_IP}/${CURRENT_CIDR}${NC}"
        echo -e "  ${BOLD}Current Gateway:${NC}  ${GREEN}${CURRENT_GATEWAY}${NC}"
        echo -e "  ${BOLD}Current DNS:${NC}      ${GREEN}${CURRENT_DNS}${NC}"
    else
        echo -e "  ${RED}Warning: Interface ${INTERFACE} does not exist!${NC}"
        echo -e "  ${YELLOW}Available interfaces: ${CURRENT_INTERFACES}${NC}"
    fi
    echo ""
    
    # Show current hosts file content
    if [ "$UPDATE_HOSTS" = "yes" ]; then
        echo -e "  ${BOLD}Current Hosts Entries:${NC}"
        grep -v "^#" /etc/hosts | grep -v "^$" | sed 's/^/    /'
        echo ""
    fi
}

# Display planned changes
show_planned_changes() {
    echo -e "${BOLD}${CYAN}========================================${NC}"
    echo -e "${BOLD}${CYAN}       PLANNED CONFIGURATION            ${NC}"
    echo -e "${BOLD}${CYAN}========================================${NC}"
    echo ""
    
    # Initialize change flags
    HOSTNAME_CHANGED=false
    IP_CHANGED=false
    GATEWAY_CHANGED=false
    DNS_CHANGED=false
    HOSTS_CHANGED=false
    
    # Hostname changes
    echo -e "  ${BOLD}1. Hostname Change:${NC}"
    if [ "$CURRENT_HOSTNAME" != "$HOSTNAME" ]; then
        echo -e "     ${RED}${CURRENT_HOSTNAME}${NC} ${BOLD}->${NC} ${GREEN}${HOSTNAME}${NC}"
        HOSTNAME_CHANGED=true
    else
        echo -e "     ${YELLOW}No change (already ${HOSTNAME})${NC}"
    fi
    echo ""
    
    # Network configuration changes
    echo -e "  ${BOLD}2. Network Configuration:${NC}"
    echo -e "     ${BOLD}Interface:${NC} ${CYAN}${INTERFACE}${NC}"
    
    if [ "$CURRENT_IP" != "$IP_ADDRESS" ]; then
        echo -e "     ${BOLD}IP Address:${NC}  ${RED}${CURRENT_IP}${NC} ${BOLD}->${NC} ${GREEN}${IP_ADDRESS}${NC}"
        IP_CHANGED=true
    else
        echo -e "     ${BOLD}IP Address:${NC}  ${YELLOW}No change (${IP_ADDRESS})${NC}"
    fi
    
    echo -e "     ${BOLD}Netmask:${NC}      ${GREEN}${NETMASK}${NC}"
    
    if [ "$CURRENT_GATEWAY" != "$GATEWAY" ]; then
        echo -e "     ${BOLD}Gateway:${NC}     ${RED}${CURRENT_GATEWAY}${NC} ${BOLD}->${NC} ${GREEN}${GATEWAY}${NC}"
        GATEWAY_CHANGED=true
    else
        echo -e "     ${BOLD}Gateway:${NC}     ${YELLOW}No change (${GATEWAY})${NC}"
    fi
    
    if [ "$CURRENT_DNS" != "$DNS_SERVERS" ]; then
        echo -e "     ${BOLD}DNS:${NC}         ${RED}${CURRENT_DNS}${NC} ${BOLD}->${NC} ${GREEN}${DNS_SERVERS}${NC}"
        DNS_CHANGED=true
    else
        echo -e "     ${BOLD}DNS:${NC}         ${YELLOW}No change (${DNS_SERVERS})${NC}"
    fi
    echo ""
    
    # Netplan/Interfaces configuration method
    if [ "$USE_NETPLAN" = "yes" ]; then
        echo -e "  ${BOLD}3. Configuration Method:${NC} ${CYAN}Netplan${NC}"
    else
        echo -e "  ${BOLD}3. Configuration Method:${NC} ${CYAN}Traditional interfaces${NC}"
    fi
    echo ""
    
    # Hosts file changes
    echo -e "  ${BOLD}4. Hosts File Updates:${NC}"
    if [ "$UPDATE_HOSTS" = "yes" ]; then
        echo -e "     ${GREEN}Will update /etc/hosts${NC}"
        echo -e "     ${BOLD}Format: IP_ADDRESS<tab>HOSTNAME${NC}"
        if [ "${#HOSTS_ENTRIES[@]}" -gt 0 ]; then
            echo -e "     ${BOLD}Entries to add/update:${NC}"
            for entry in "${HOSTS_ENTRIES[@]}"; do
                hostname=$(echo "$entry" | cut -d: -f1)
                ip_addr=$(echo "$entry" | cut -d: -f2)
                echo -e "       ${CYAN}${ip_addr}${NC}	${GREEN}${hostname}${NC}"
            done
        fi
        HOSTS_CHANGED=true
    else
        echo -e "     ${YELLOW}Will NOT update /etc/hosts${NC}"
    fi
    echo ""
    
    # Summary of changes
    echo -e "${BOLD}${CYAN}========================================${NC}"
    echo -e "${BOLD}${CYAN}          CHANGE SUMMARY                 ${NC}"
    echo -e "${BOLD}${CYAN}========================================${NC}"
    echo ""
    
    total_changes=0
    if [ "$HOSTNAME_CHANGED" = "true" ]; then
        echo -e "  ${GREEN}[+]${NC} Hostname will be changed"
        total_changes=$((total_changes + 1))
    fi
    if [ "$IP_CHANGED" = "true" ]; then
        echo -e "  ${GREEN}[+]${NC} IP address will be changed"
        total_changes=$((total_changes + 1))
    fi
    if [ "$GATEWAY_CHANGED" = "true" ]; then
        echo -e "  ${GREEN}[+]${NC} Gateway will be changed"
        total_changes=$((total_changes + 1))
    fi
    if [ "$DNS_CHANGED" = "true" ]; then
        echo -e "  ${GREEN}[+]${NC} DNS servers will be changed"
        total_changes=$((total_changes + 1))
    fi
    if [ "$HOSTS_CHANGED" = "true" ]; then
        echo -e "  ${GREEN}[+]${NC} Hosts file will be updated"
        total_changes=$((total_changes + 1))
    fi
    
    if [ $total_changes -eq 0 ]; then
        echo -e "  ${YELLOW}No changes detected - system already matches configuration${NC}"
    else
        echo -e "  ${BOLD}Total changes: ${total_changes}${NC}"
    fi
    echo ""
    
    # Warning about remote connection
    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
        echo -e "${RED}${BOLD}========================================${NC}"
        echo -e "${RED}${BOLD}  WARNING: You are connected via SSH!   ${NC}"
        echo -e "${RED}${BOLD}  Changing network settings may cause   ${NC}"
        echo -e "${RED}${BOLD}  connection loss!                      ${NC}"
        echo -e "${RED}${BOLD}========================================${NC}"
        echo ""
    fi
}

# Convert subnet mask to CIDR
mask_to_cidr() {
    mask="$1"
    cidr=0
    IFS=.
    for octet in $mask; do
        case $octet in
            255) cidr=$((cidr + 8));;
            254) cidr=$((cidr + 7));;
            252) cidr=$((cidr + 6));;
            248) cidr=$((cidr + 5));;
            240) cidr=$((cidr + 4));;
            224) cidr=$((cidr + 3));;
            192) cidr=$((cidr + 2));;
            128) cidr=$((cidr + 1));;
            0) ;;
            *) 
                log_error "Invalid subnet mask: $mask"
                exit 1
                ;;
        esac
    done
    echo "$cidr"
}

# Modify hostname
change_hostname() {
    log_step "Modifying hostname to: $HOSTNAME"
    
    old_hostname=$(hostname)
    
    # Use hostnamectl to set hostname
    if command -v hostnamectl >/dev/null 2>&1; then
        hostnamectl set-hostname "$HOSTNAME"
    fi
    
    # Update /etc/hostname
    echo "$HOSTNAME" > /etc/hostname
    
    log_info "Hostname changed from '${old_hostname}' to '${HOSTNAME}'"
}

# Configure Netplan network (Ubuntu 24 default method)
configure_netplan() {
    interface="$1"
    ip_address="$2"
    netmask="$3"
    gateway="$4"
    dns_servers="$5"
    
    log_step "Configuring network interface using Netplan: $interface"
    
    # Convert subnet mask to CIDR format
    cidr=$(mask_to_cidr "$netmask")
    
    # Create Netplan configuration file
    netplan_config="/etc/netplan/01-netcfg.yaml"
    netplan_backup="/etc/netplan/01-netcfg.yaml.bak.$(date +%Y%m%d%H%M%S)"
    
    # Backup original configuration
    if [ -f "$netplan_config" ]; then
        cp "$netplan_config" "$netplan_backup"
        log_info "Original Netplan configuration backed up to: $netplan_backup"
    fi
    
    # Generate DNS addresses list
    dns_list=""
    for dns in $dns_servers; do
        dns_list="$dns_list\n            - $dns"
    done
    
    # Generate new configuration file
    cat > "$netplan_config" << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $interface:
      addresses:
        - $ip_address/$cidr
      nameservers:
        addresses:$(echo -e "$dns_list")
      routes:
        - to: default
          via: $gateway
EOF
    
    log_info "Netplan configuration file updated"
    
    # Apply configuration
    log_info "Applying network configuration..."
    if command -v netplan >/dev/null 2>&1; then
        netplan apply
        log_info "Netplan configuration applied successfully"
    else
        log_error "netplan command not found"
        exit 1
    fi
}

# Configure traditional interfaces file (alternative method)
configure_interfaces() {
    interface="$1"
    ip_address="$2"
    netmask="$3"
    gateway="$4"
    dns_servers="$5"
    
    log_step "Configuring network interface using traditional method: $interface"
    
    interfaces_file="/etc/network/interfaces"
    interfaces_backup="${interfaces_file}.bak.$(date +%Y%m%d%H%M%S)"
    
    # Backup original configuration
    if [ -f "$interfaces_file" ]; then
        cp "$interfaces_file" "$interfaces_backup"
        log_info "Original interfaces configuration backed up to: $interfaces_backup"
    fi
    
    # Configure network interface
    cat > "$interfaces_file" << EOF
# Auto-configured network interface
auto lo
iface lo inet loopback

auto $interface
iface $interface inet static
    address $ip_address
    netmask $netmask
    gateway $gateway
    dns-nameservers $dns_servers
EOF
    
    log_info "Interfaces configuration file updated"
    
    # Restart network service
    log_info "Restarting network service..."
    if systemctl is-active --quiet networking 2>/dev/null; then
        systemctl restart networking
    fi
    
    log_info "Network service restarted successfully"
}

# Configure DNS
configure_dns() {
    dns_servers="$1"
    
    log_step "Configuring DNS servers"
    
    # Ubuntu 24 uses systemd-resolved for DNS management
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        log_info "Using systemd-resolved for DNS configuration"
        
        # Configure systemd-resolved
        resolved_conf="/etc/systemd/resolved.conf"
        resolved_backup="${resolved_conf}.bak.$(date +%Y%m%d%H%M%S)"
        
        if [ -f "$resolved_conf" ]; then
            cp "$resolved_conf" "$resolved_backup"
        fi
        
        # Update DNS configuration
        if [ -f "$resolved_conf" ]; then
            sed -i "s/^#DNS=.*/DNS=${dns_servers}/" "$resolved_conf"
            sed -i "s/^DNS=.*/DNS=${dns_servers}/" "$resolved_conf"
        fi
        
        systemctl restart systemd-resolved
        log_info "systemd-resolved restarted successfully"
    else
        # Traditional resolv.conf method
        resolv_file="/etc/resolv.conf"
        resolv_backup="${resolv_file}.bak.$(date +%Y%m%d%H%M%S)"
        
        if [ -f "$resolv_file" ]; then
            cp "$resolv_file" "$resolv_backup"
        fi
        
        > "$resolv_file"
        for dns in $dns_servers; do
            echo "nameserver $dns" >> "$resolv_file"
        done
        
        log_info "resolv.conf updated successfully"
    fi
}

# Fix hosts file format
fix_hosts_format() {
    log_step "Fixing hosts file format"
    
    hosts_file="/etc/hosts"
    
    # Create a temporary file
    tmp_hosts=$(mktemp)
    
    # Process hosts file line by line
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines
        if [ -z "$line" ]; then
            echo "" >> "$tmp_hosts"
            continue
        fi
        
        # Keep comment lines unchanged
        if echo "$line" | grep -q "^[[:space:]]*#"; then
            echo "$line" >> "$tmp_hosts"
            continue
        fi
        
        # Keep IPv6 entries unchanged
        if echo "$line" | grep -q ":"; then
            echo "$line" >> "$tmp_hosts"
            continue
        fi
        
        # Fix format: replace literal \t with actual tab, ensure proper spacing
        # Remove literal \t and replace with actual tab
        fixed_line=$(echo "$line" | sed 's/\\t/\t/g')
        
        # Ensure proper format: IP<space(s) or tab>hostname(s)
        # Replace multiple spaces/tabs with a single tab between IP and hostname
        ip_part=$(echo "$fixed_line" | awk '{print $1}')
        host_part=$(echo "$fixed_line" | awk '{for(i=2;i<=NF;i++) printf "%s ", $i}' | sed 's/ $//')
        
        if [ -n "$ip_part" ] && [ -n "$host_part" ]; then
            echo "${ip_part}	${host_part}" >> "$tmp_hosts"
        else
            echo "$line" >> "$tmp_hosts"
        fi
    done < "$hosts_file"
    
    # Replace original file with fixed version
    mv "$tmp_hosts" "$hosts_file"
    
    log_info "Hosts file format fixed successfully"
}

# Update hosts file
update_hosts_file() {
    if [ "$UPDATE_HOSTS" != "yes" ]; then
        log_info "Skipping hosts file update"
        return
    fi
    
    log_step "Updating hosts file"
    
    # First fix existing format issues
    fix_hosts_format
    
    hosts_file="/etc/hosts"
    hosts_backup="${hosts_file}.bak.$(date +%Y%m%d%H%M%S)"
    
    # Backup after fixing format
    cp "$hosts_file" "$hosts_backup"
    log_info "Hosts file backed up to: $hosts_backup"
    
    # Process each mapping entry
    if [ "${#HOSTS_ENTRIES[@]}" -gt 0 ]; then
        for entry in "${HOSTS_ENTRIES[@]}"; do
            hostname=$(echo "$entry" | cut -d: -f1)
            ip_addr=$(echo "$entry" | cut -d: -f2)
            
            if [ -z "$hostname" ] || [ -z "$ip_addr" ]; then
                log_warn "Skipping invalid entry: $entry"
                continue
            fi
            
            # Check if hostname already exists in hosts file
            if grep -q "^[^#]*[[:space:]]${hostname}" "$hosts_file" 2>/dev/null; then
                # Update existing entry - replace the entire line
                sed -i "/[[:space:]]${hostname}/d" "$hosts_file"
                log_info "Removed old hosts entry for: $hostname"
            fi
            
            # Also check if IP already exists
            if grep -q "^${ip_addr}[[:space:]]" "$hosts_file" 2>/dev/null; then
                # Update existing IP entry
                sed -i "/^${ip_addr}[[:space:]]/d" "$hosts_file"
                log_info "Removed old hosts entry for IP: $ip_addr"
            fi
            
            # Add new entry with proper format (tab separator)
            echo "${ip_addr}	${hostname}" >> "$hosts_file"
            log_info "Added hosts entry: ${ip_addr}	${hostname}"
        done
    fi
    
    log_info "Hosts file updated successfully"
}

# Verify network configuration
verify_network() {
    log_step "Verifying network configuration..."
    
    echo ""
    echo -e "${BOLD}${CYAN}========================================${NC}"
    echo -e "${BOLD}${CYAN}       VERIFICATION RESULTS              ${NC}"
    echo -e "${BOLD}${CYAN}========================================${NC}"
    echo ""
    
    # Hostname verification
    echo -e "  ${BOLD}Hostname:${NC}"
    new_hostname=$(hostnamectl status --static 2>/dev/null || hostname)
    echo -e "    ${GREEN}${new_hostname}${NC}"
    echo ""
    
    # Network interface verification
    echo -e "  ${BOLD}Network Interface (${INTERFACE}):${NC}"
    ip -4 addr show "$INTERFACE" 2>/dev/null | grep -E "inet" | sed 's/^/    /'
    echo ""
    
    # Routing table verification
    echo -e "  ${BOLD}Routing Table:${NC}"
    ip route show 2>/dev/null | sed 's/^/    /'
    echo ""
    
    # DNS configuration verification
    echo -e "  ${BOLD}DNS Configuration:${NC}"
    if command -v resolvectl >/dev/null 2>&1; then
        resolvectl status 2>/dev/null | grep -E "DNS Servers|Current DNS" | sed 's/^/    /'
    fi
    
    if [ -z "$(resolvectl status 2>/dev/null)" ]; then
        grep nameserver /etc/resolv.conf 2>/dev/null | sed 's/^/    /'
    fi
    echo ""
    
    # Hosts file verification
    if [ "$UPDATE_HOSTS" = "yes" ]; then
        echo -e "  ${BOLD}Updated Hosts Entries:${NC}"
        grep -v "^#" /etc/hosts | grep -v "^$" | grep -v "ip6-" | grep -v "ff0" | sed 's/^/    /'
        echo ""
    fi
    
    # Network connectivity test
    echo -e "  ${BOLD}Network Connectivity Test:${NC}"
    if ping -c 2 -W 2 "$GATEWAY" > /dev/null 2>&1; then
        echo -e "    Gateway ${GATEWAY}: ${GREEN}Reachable${NC}"
    else
        echo -e "    Gateway ${GATEWAY}: ${RED}Unreachable${NC}"
    fi
    
    if ping -c 2 -W 2 "8.8.8.8" > /dev/null 2>&1; then
        echo -e "    External Network: ${GREEN}Reachable${NC}"
    else
        echo -e "    External Network: ${RED}Unreachable${NC}"
    fi
    echo ""
}

# Apply all changes
apply_changes() {
    echo ""
    log_info "Starting configuration changes..."
    echo ""
    
    # 1. Modify hostname
    if [ "$HOSTNAME_CHANGED" = "true" ]; then
        change_hostname
        echo ""
    else
        log_info "Skipping hostname change (no change needed)"
        echo ""
    fi
    
    # 2. Configure network
    if [ "$IP_CHANGED" = "true" ] || [ "$GATEWAY_CHANGED" = "true" ] || [ "$DNS_CHANGED" = "true" ]; then
        if [ "$USE_NETPLAN" = "yes" ]; then
            configure_netplan "$INTERFACE" "$IP_ADDRESS" "$NETMASK" "$GATEWAY" "$DNS_SERVERS"
        else
            configure_interfaces "$INTERFACE" "$IP_ADDRESS" "$NETMASK" "$GATEWAY" "$DNS_SERVERS"
        fi
        echo ""
    else
        log_info "Skipping network configuration (no change needed)"
        echo ""
    fi
    
    # 3. Configure DNS
    if [ "$DNS_CHANGED" = "true" ]; then
        configure_dns "$DNS_SERVERS"
        echo ""
    else
        log_info "Skipping DNS configuration (no change needed)"
        echo ""
    fi
    
    # 4. Update hosts file
    if [ "$HOSTS_CHANGED" = "true" ]; then
        update_hosts_file
        echo ""
    else
        log_info "Skipping hosts file update (no change needed)"
        echo ""
    fi
    
    # 5. Verify configuration
    verify_network
    
    echo ""
    log_info "Configuration completed!"
    log_warn "It is recommended to reboot the system: sudo reboot"
}

# Main function
main() {
    echo ""
    echo -e "${BOLD}${CYAN}========================================${NC}"
    echo -e "${BOLD}${CYAN}  Ubuntu 24 Network Configuration Script ${NC}"
    echo -e "${BOLD}${CYAN}========================================${NC}"
    echo ""
    
    # Check root privileges
    check_root
    
    # Load configuration
    load_config
    
    # Get current system information
    get_current_info
    
    # Display current configuration
    show_current_config
    
    # Display planned changes
    show_planned_changes
    
    # Check if there are any changes to make
    if [ "$HOSTNAME_CHANGED" = "false" ] && [ "$IP_CHANGED" = "false" ] && 
       [ "$GATEWAY_CHANGED" = "false" ] && [ "$DNS_CHANGED" = "false" ] && 
       [ "$HOSTS_CHANGED" = "false" ]; then
        log_info "No changes needed. System already matches configuration."
        exit 0
    fi
    
    # Ask for confirmation before applying changes
    echo -e "${YELLOW}${BOLD}Do you want to apply these changes?${NC}"
    echo -e "Type '${GREEN}yes${NC}' to proceed, or anything else to cancel: "
    read -r confirm
    
    if [ "$confirm" != "yes" ]; then
        log_info "Operation cancelled by user"
        exit 0
    fi
    
    # Final confirmation for SSH connections
    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
        echo ""
        echo -e "${RED}${BOLD}========================================${NC}"
        echo -e "${RED}${BOLD}  FINAL WARNING FOR SSH CONNECTION      ${NC}"
        echo -e "${RED}${BOLD}  You may lose connection!              ${NC}"
        echo -e "${RED}${BOLD}  Are you absolutely sure?              ${NC}"
        echo -e "${RED}${BOLD}========================================${NC}"
        echo ""
        echo -e "Type '${GREEN}I understand${NC}' to proceed anyway: "
        read -r ssh_confirm
        
        if [ "$ssh_confirm" != "I understand" ]; then
            log_info "Operation cancelled by user"
            exit 0
        fi
    fi
    
    # Apply all changes
    apply_changes
}

# Execute main function
main "$@"