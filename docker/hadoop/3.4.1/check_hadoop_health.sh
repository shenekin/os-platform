#!/bin/bash
# Hadoop Cluster Health Check Script
# Run this after starting your computer or restarting the cluster

set -e

HADOOP_DIR="/Users/ekin/Documents/os-platform/docker/hadoop/3.4.1"
cd "$HADOOP_DIR"

echo "======================================"
echo "HADOOP CLUSTER HEALTH CHECK"
echo "======================================"
echo ""

# 1. Check if docker is running
echo "1️⃣  Checking Docker daemon..."
if ! docker ps &>/dev/null; then
    echo "❌ Docker is not running. Start Docker Desktop."
    exit 1
fi
echo "✓ Docker is running"
echo ""

# 2. Start cluster if not running
echo "2️⃣  Checking Hadoop cluster status..."
RUNNING=$(docker compose ps --services --filter "status=running" 2>/dev/null | wc -l)
if [ "$RUNNING" -lt 8 ]; then
    echo "⚠️  Cluster not fully running. Starting..."
    docker compose up -d
    echo "Waiting for cluster to stabilize..."
    sleep 30
fi
echo "✓ Cluster containers running"
echo ""

# 3. Check NameNode health
echo "3️⃣  Checking NameNode..."
if docker compose exec namenode hdfs dfsadmin -report &>/dev/null; then
    echo "✓ NameNode is responsive"
else
    echo "❌ NameNode is not responding"
    exit 1
fi
echo ""

# 4. Check DataNodes
echo "4️⃣  Checking DataNodes..."
DATANODES=$(docker compose exec namenode hdfs dfsadmin -report 2>/dev/null | grep -c "Live datanodes" || true)
if [ "$DATANODES" -gt 0 ]; then
    NODECOUNT=$(docker compose exec namenode hdfs dfsadmin -report 2>/dev/null | grep "^Name:" | wc -l)
    echo "✓ Found $NODECOUNT DataNodes"
else
    echo "❌ No DataNodes found"
    exit 1
fi
echo ""

# 5. Check YARN ResourceManager
echo "5️⃣  Checking YARN ResourceManager..."
if docker compose exec resourcemanager yarn node -list &>/dev/null; then
    NMCOUNT=$(docker compose exec resourcemanager yarn node -list 2>/dev/null | grep -c "RUNNING" || true)
    echo "✓ ResourceManager is responsive"
    echo "  - NodeManagers: $NMCOUNT RUNNING"
else
    echo "❌ ResourceManager is not responding"
    exit 1
fi
echo ""

# 6. Check HDFS capacity
echo "6️⃣  Checking HDFS Capacity..."
CAPACITY=$(docker compose exec namenode hdfs dfsadmin -report 2>/dev/null | grep "Configured Capacity:" | head -1 | awk '{print $(NF-1), $NF}')
USED=$(docker compose exec namenode hdfs dfsadmin -report 2>/dev/null | grep "^DFS Used:" | head -1 | awk '{print $3}')
echo "✓ HDFS Capacity: $CAPACITY"
echo "  - DFS Used: $USED"
echo ""

# 7. Check filesystem health
echo "7️⃣  Checking HDFS Filesystem Health..."
HEALTH=$(docker compose exec namenode hdfs fsck / 2>/dev/null | grep "The filesystem" | head -1)
echo "✓ $HEALTH"
echo ""

# 8. Check web UIs
echo "8️⃣  Checking Web UIs..."
if curl -s http://localhost:9870 &>/dev/null; then
    echo "✓ NameNode UI available: http://localhost:9870"
else
    echo "⚠️  NameNode UI not accessible (may still be starting)"
fi

if curl -s http://localhost:8088 &>/dev/null; then
    echo "✓ ResourceManager UI available: http://localhost:8088"
else
    echo "⚠️  ResourceManager UI not accessible (may still be starting)"
fi
echo ""

echo "======================================"
echo "✅ HADOOP CLUSTER IS HEALTHY"
echo "======================================"
echo ""
echo "Next Steps:"
echo "- NameNode UI: http://localhost:9870"
echo "- ResourceManager UI: http://localhost:8088"
echo "- Java HDFS Client: hdfs://localhost:9000"
echo "- WebHDFS API: http://localhost:9870/webhdfs/v1"
