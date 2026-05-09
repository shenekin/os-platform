#!/bin/bash
set -euo pipefail

echo "==================================="
echo "Hadoop 3.4.1 Cluster Setup"
echo "==================================="

# Create entrypoint script
echo "[1/3] Creating hadoop-entrypoint.sh..."
cat > hadoop-entrypoint.sh << 'ENTRYPOINT'
#!/usr/bin/env bash
set -euo pipefail

mkdir -p /run/sshd
ssh-keygen -A 2>/dev/null || true

export JAVA_HOME=/opt/java/openjdk
export HADOOP_HOME=/opt/hadoop-3.4.1
export HADOOP_CONF_DIR="${HADOOP_HOME}/etc/hadoop"
export PATH="${PATH}:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin"

# Fix JAVA_HOME in hadoop-env.sh
sed -i '54s|^# export JAVA_HOME=|export JAVA_HOME=/opt/java/openjdk|' "${HADOOP_CONF_DIR}/hadoop-env.sh"

if ! grep -q '^export HADOOP_NICENESS=' "${HADOOP_CONF_DIR}/hadoop-env.sh"; then
  echo 'export HADOOP_NICENESS=0' >> "${HADOOP_CONF_DIR}/hadoop-env.sh"
fi

# Patch core-site.xml and hdfs-site.xml to use localhost
CORE_SITE="${HADOOP_CONF_DIR}/core-site.xml"
HDFS_SITE="${HADOOP_CONF_DIR}/hdfs-site.xml"

# Fix core-site.xml namenode address
sed -i 's|hdfs://namenode:9000|hdfs://127.0.0.1:9000|g' "$CORE_SITE"

# Add namenode address properties to hdfs-site.xml
cat > /tmp/namenode_props.xml << 'PROPS'
  <property>
    <name>dfs.namenode.rpc-address</name>
    <value>127.0.0.1:9000</value>
  </property>
  <property>
    <name>dfs.namenode.http-address</name>
    <value>127.0.0.1:9870</value>
  </property>
PROPS

sed -i '/<\/configuration>/d' "$HDFS_SITE"
cat /tmp/namenode_props.xml >> "$HDFS_SITE"
echo '</configuration>' >> "$HDFS_SITE"

mkdir -p /tmp/hadoop-root /tmp/hadoop-hadoop "${HADOOP_HOME}/logs"
chown -R hadoop:hadoop /tmp/hadoop-hadoop "${HADOOP_HOME}/logs" 2>/dev/null || true

# Ensure namenode directory is writable
NAMENODE_DIR="/hadoop/dfs/name"
mkdir -p "$NAMENODE_DIR"
chown -R hadoop:hadoop "$NAMENODE_DIR" 2>/dev/null || true
chmod 755 "$NAMENODE_DIR" 2>/dev/null || true

# Ensure datanode directory is writable
DATANODE_DIR="/hadoop/dfs/data"
mkdir -p "$DATANODE_DIR"
chown -R hadoop:hadoop "$DATANODE_DIR" 2>/dev/null || true
chmod 755 "$DATANODE_DIR" 2>/dev/null || true

if [ ! -d "${NAMENODE_DIR}/current" ]; then
  sudo -u hadoop "${HADOOP_HOME}/bin/hdfs" namenode -format -force -nonInteractive 2>&1 | tail -5 || true
fi

/usr/sbin/sshd

# Direct start for host network
case "${HADOOP_NODE_TYPE:-namenode}" in
  namenode)
    sudo -u hadoop "${HADOOP_HOME}/bin/hdfs" namenode &
    NAMENODE_PID=$!
    sleep 3
    tail -F "${HADOOP_HOME}"/logs/*namenode*.log 2>/dev/null &
    wait $NAMENODE_PID
    ;;
  datanode)
    sleep 8
    sudo -u hadoop "${HADOOP_HOME}/bin/hdfs" datanode &
    DATANODE_PID=$!
    tail -F "${HADOOP_HOME}"/logs/*datanode*.log 2>/dev/null &
    wait $DATANODE_PID
    ;;
  *)
    sleep infinity
    ;;
esac
ENTRYPOINT

chmod +x hadoop-entrypoint.sh

# Create docker-compose.yml
echo "[2/3] Creating docker-compose.yml..."
cat > docker-compose.yml << 'COMPOSE'
services:
  namenode:
    image: ekinshen/hadoop-with-configuration:3.4.1
    container_name: hadoop-namenode
    network_mode: host
    environment:
      - HADOOP_NODE_TYPE=namenode
      - HDFS_NAMENODE_HOSTNAME=localhost
      - JAVA_HOME=/opt/java/openjdk
    volumes:
      - namenode-data:/hadoop/dfs/name
      - ./hadoop-entrypoint.sh:/hadoop-entrypoint.sh:ro
    entrypoint: /hadoop-entrypoint.sh
    restart: unless-stopped

  datanode1:
    image: ekinshen/hadoop-with-configuration:3.4.1
    container_name: hadoop-datanode1
    network_mode: host
    environment:
      - HADOOP_NODE_TYPE=datanode
      - HDFS_NAMENODE_HOSTNAME=localhost
      - JAVA_HOME=/opt/java/openjdk
    volumes:
      - datanode1-data:/hadoop/dfs/data
      - ./hadoop-entrypoint.sh:/hadoop-entrypoint.sh:ro
    entrypoint: /hadoop-entrypoint.sh
    depends_on:
      - namenode
    restart: unless-stopped

  datanode2:
    image: ekinshen/hadoop-with-configuration:3.4.1
    container_name: hadoop-datanode2
    network_mode: host
    environment:
      - HADOOP_NODE_TYPE=datanode
      - HDFS_NAMENODE_HOSTNAME=localhost
      - JAVA_HOME=/opt/java/openjdk
    volumes:
      - datanode2-data:/hadoop/dfs/data
      - ./hadoop-entrypoint.sh:/hadoop-entrypoint.sh:ro
    entrypoint: /hadoop-entrypoint.sh
    depends_on:
      - namenode
    restart: unless-stopped

volumes:
  namenode-data:
  datanode1-data:
  datanode2-data:
COMPOSE

# Create README
echo "[3/3] Creating README.md..."
cat > README.md << 'README'
# Hadoop 3.4.1 Cluster with Host Network

A Docker-based Hadoop HDFS cluster using `ekinshen/hadoop-with-configuration:3.4.1` with host network mode enabled.

## Architecture

- **NameNode**: Runs on `localhost:9000` (RPC) and `localhost:9870` (Web UI)
- **DataNodes**: Two datanodes for distributed storage, connected via host network
- **Storage**: ~1TB aggregate capacity across all datanodes
- **Configuration**: Automatically configured for localhost addresses

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Port 9000, 9866, 9870 available on localhost

### Start Cluster

```bash
docker compose up -d
```

Wait ~60 seconds for full initialization. Check status:

```bash
docker compose ps
```

All three containers should show `Up`:

```
CONTAINER ID   STATUS                 NAMES
xxx            Up About a minute      hadoop-namenode
yyy            Up About a minute      hadoop-datanode1
zzz            Up About a minute      hadoop-datanode2
```

### Stop Cluster

```bash
docker compose down
```

To remove all data and volumes:

```bash
docker compose down -v
```

## Access & Commands

### Web UI

Open in browser:
- **NameNode UI**: http://localhost:9870

### Check Cluster Health

```bash
docker exec hadoop-namenode bash -c 'source /opt/hadoop-3.4.1/etc/hadoop/hadoop-env.sh && /opt/hadoop-3.4.1/bin/hdfs dfsadmin -report'
```

### Upload Test File

```bash
echo "test data" | docker exec -i hadoop-namenode bash -c 'source /opt/hadoop-3.4.1/etc/hadoop/hadoop-env.sh && hdfs dfs -put - /test.txt'
```

### List HDFS Files

```bash
docker exec hadoop-namenode bash -c 'source /opt/hadoop-3.4.1/etc/hadoop/hadoop-env.sh && hdfs dfs -ls /'
```

### Read File from HDFS

```bash
docker exec hadoop-namenode bash -c 'source /opt/hadoop-3.4.1/etc/hadoop/hadoop-env.sh && hdfs dfs -cat /test.txt'
```

### View Logs

NameNode logs:
```bash
docker logs hadoop-namenode
```

DataNode logs:
```bash
docker logs hadoop-datanode1
docker logs hadoop-datanode2
```

## Configuration

The cluster is pre-configured for host network mode:

- **core-site.xml**: NameNode address set to `hdfs://127.0.0.1:9000`
- **hdfs-site.xml**: NameNode RPC on `127.0.0.1:9000`, Web UI on `127.0.0.1:9870`
- **Replication factor**: 3 (default)
- **Permissions**: Disabled for ease of testing

## Volumes

Data persists in Docker volumes:

- `namenode-data`: NameNode metadata
- `datanode1-data`: DataNode 1 storage
- `datanode2-data`: DataNode 2 storage

View volumes:
```bash
docker volume ls | grep hadoop
```

## Troubleshooting

### Containers not starting

Check logs:
```bash
docker compose logs -f
```

Common issues:
- Port 9000/9870 already in use: Stop conflicting services or change ports
- Slow system: Wait 2+ minutes for initialization (especially first run)

### DataNode not registering

Check datanode logs:
```bash
docker logs hadoop-datanode1
```

If permission errors, ensure data directories are writable. The `hadoop-entrypoint.sh` script handles this automatically.

### HDFS commands fail with "namenode: Name or service not known"

This indicates a stale configuration. Restart the cluster:
```bash
docker compose down -v
docker compose up -d
```

## Files

- `docker-compose.yml`: Cluster definition with 3 services (namenode + 2 datanodes)
- `hadoop-entrypoint.sh`: Initialization script that patches configs for localhost and sets permissions
- `README.md`: This file

## Performance Notes

- First startup takes ~60 seconds (JAVA_HOME setup, namenode formatting)
- Subsequent restarts take ~15 seconds
- Host network mode provides near-native I/O performance
- Replication factor 3 reduces usable space by 66%

## License

Uses ekinshen/hadoop-with-configuration:3.4.1 image. Apache Hadoop licensed under Apache License 2.0.
README

echo ""
echo "==================================="
echo "✓ Setup Complete!"
echo "==================================="
echo ""
echo "Files created:"
echo "  ✓ hadoop-entrypoint.sh (executable)"
echo "  ✓ docker-compose.yml"
echo "  ✓ README.md"
echo ""
echo "Next steps:"
echo "  1. Start cluster:  docker compose up -d"
echo "  2. Wait 60 seconds for initialization"
echo "  3. Check status:   docker compose ps"
echo "  4. Access UI:      http://localhost:9870"
echo ""
echo "See README.md for full commands and troubleshooting."
echo ""
