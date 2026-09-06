#!/usr/bin/env bash

# Hadoop Cluster Validation Script

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

print_header() {
    echo -e "\n${BLUE}======================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}======================================${NC}\n"
}

print_check() {
    echo -n "  [ ] $1 ... "
}

print_pass() {
    echo -e "${GREEN}✓ PASS${NC}"
    ((CHECKS_PASSED++))
}

print_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((CHECKS_FAILED++))
}

print_warn() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
    ((CHECKS_WARNING++))
}

print_result() {
    echo ""
    echo -e "${BLUE}======================================${NC}"
    echo -e "Summary:"
    echo -e "  ${GREEN}Passed: $CHECKS_PASSED${NC}"
    echo -e "  ${RED}Failed: $CHECKS_FAILED${NC}"
    echo -e "  ${YELLOW}Warnings: $CHECKS_WARNING${NC}"
    echo -e "${BLUE}======================================${NC}\n"
    
    if [ $CHECKS_FAILED -gt 0 ]; then
        echo -e "${RED}Validation FAILED${NC}"
        return 1
    else
        echo -e "${GREEN}Validation PASSED${NC}"
        return 0
    fi
}

# Check if Docker is installed
print_header "Docker Installation Check"
print_check "Docker is installed"
if command -v docker &> /dev/null; then
    print_pass
else
    print_fail "Docker is not installed"
    exit 1
fi

# Check if Docker Compose is installed
print_check "Docker Compose is installed"
if command -v docker-compose &> /dev/null; then
    print_pass
else
    print_fail "Docker Compose is not installed"
    exit 1
fi

# Check configuration files
print_header "Configuration Files Check"

print_check "docker-compose.yml exists"
if [ -f "docker-compose.yml" ]; then
    print_pass
else
    print_fail "docker-compose.yml not found"
fi

print_check "conf/core-site.xml exists"
if [ -f "conf/core-site.xml" ]; then
    print_pass
else
    print_fail "conf/core-site.xml not found"
fi

print_check "conf/hdfs-site.xml exists"
if [ -f "conf/hdfs-site.xml" ]; then
    print_pass
else
    print_fail "conf/hdfs-site.xml not found"
fi

print_check "hadoop-entrypoint.sh exists"
if [ -f "hadoop-entrypoint.sh" ]; then
    print_pass
else
    print_fail "hadoop-entrypoint.sh not found"
fi

print_check "workers file exists"
if [ -f "workers" ]; then
    print_pass
else
    print_fail "workers file not found"
fi

# Check configuration file content
print_header "Configuration Content Validation"

print_check "core-site.xml has fs.defaultFS set to namenode:8020"
if grep -q 'namenode:8020' "conf/core-site.xml"; then
    print_pass
else
    print_warn "core-site.xml does not reference namenode:8020"
fi

print_check "hdfs-site.xml has dfs.namenode.rpc-address set to namenode:8020"
if grep -q 'namenode:8020' "conf/hdfs-site.xml"; then
    print_pass
else
    print_warn "hdfs-site.xml does not reference namenode:8020"
fi

print_check "hdfs-site.xml has replication factor of 3"
if grep -q '<value>3</value>' "conf/hdfs-site.xml" | head -1; then
    print_pass
else
    print_warn "hdfs-site.xml replication factor may not be set to 3"
fi

print_check "workers file contains datanode1, datanode2, datanode3"
if grep -q 'datanode1' "workers" && grep -q 'datanode2' "workers' && grep -q 'datanode3' "workers"; then
    print_pass
else
    print_warn "workers file does not contain all three datanodes"
fi

# Check container status if cluster is running
print_header "Container Status Check"

print_check "namenode container is running"
if docker ps --format '{{.Names}}' | grep -q '^namenode$'; then
    print_pass
else
    print_warn "namenode container is not running (cluster may not be started)"
fi

print_check "datanode1 container is running"
if docker ps --format '{{.Names}}' | grep -q '^datanode1$'; then
    print_pass
else
    print_warn "datanode1 container is not running (cluster may not be started)"
fi

print_check "datanode2 container is running"
if docker ps --format '{{.Names}}' | grep -q '^datanode2$'; then
    print_pass
else
    print_warn "datanode2 container is not running (cluster may not be started)"
fi

print_check "datanode3 container is running"
if docker ps --format '{{.Names}}' | grep -q '^datanode3$'; then
    print_pass
else
    print_warn "datanode3 container is not running (cluster may not be started)"
fi

# Check network if containers are running
if docker ps --format '{{.Names}}' | grep -q '^namenode$'; then
    print_header "Network Configuration Check"
    
    print_check "hadoop-network bridge network exists"
    if docker network ls --format '{{.Name}}' | grep -q '^hadoop-network$'; then
        print_pass
    else
        print_fail "hadoop-network bridge network not found"
    fi
    
    print_check "Containers are on hadoop-network"
    if docker inspect namenode --format='{{json .NetworkSettings.Networks}}' | grep -q 'hadoop-network'; then
        print_pass
    else
        print_fail "namenode is not on hadoop-network"
    fi
    
    # Check connectivity between containers
    print_header "Container Connectivity Check"
    
    print_check "namenode can resolve datanode1"
    if docker exec namenode bash -c 'getent hosts datanode1 >/dev/null 2>&1'; then
        print_pass
    else
        print_fail "namenode cannot resolve datanode1"
    fi
    
    print_check "namenode can resolve datanode2"
    if docker exec namenode bash -c 'getent hosts datanode2 >/dev/null 2>&1'; then
        print_pass
    else
        print_fail "namenode cannot resolve datanode2"
    fi
    
    print_check "namenode can resolve datanode3"
    if docker exec namenode bash -c 'getent hosts datanode3 >/dev/null 2>&1'; then
        print_pass
    else
        print_fail "namenode cannot resolve datanode3"
    fi
    
    # Check HDFS status if NameNode is responsive
    print_header "HDFS Status Check"
    
    print_check "NameNode is responding to dfsadmin commands"
    if docker exec namenode hdfs dfsadmin -report >/dev/null 2>&1; then
        print_pass
        
        print_check "All 3 DataNodes are registered"
        LIVE_DATANODES=$(docker exec namenode hdfs dfsadmin -report 2>/dev/null | grep -c "DataNode" || true)
        if [ $LIVE_DATANODES -ge 3 ]; then
            print_pass
        else
            print_warn "Expected 3 live datanodes, but found $LIVE_DATANODES"
        fi
    else
        print_warn "NameNode is not yet responding to commands (cluster may still be initializing)"
    fi
    
    # Check port accessibility
    print_header "Port Accessibility Check"
    
    print_check "NameNode Web UI is accessible on port 9870"
    if curl -s http://localhost:9870 >/dev/null 2>&1; then
        print_pass
    else
        print_warn "NameNode Web UI is not yet accessible on port 9870"
    fi
    
    print_check "NameNode RPC port 8020 is listening"
    if netstat -tuln 2>/dev/null | grep -q ':8020' || ss -tuln 2>/dev/null | grep -q ':8020'; then
        print_pass
    else
        print_warn "Port 8020 may not be listening (this is normal if containers are still starting)"
    fi
fi

print_result
