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
