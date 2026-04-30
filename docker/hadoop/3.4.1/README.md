# Hadoop 3.4.1 Docker Cluster

Production-ready Hadoop 3.4.1 cluster running in Docker with HDFS, YARN, and WebHDFS support.

## Cluster Architecture

- **NameNode**: HDFS metadata server
- **3 DataNodes**: HDFS data storage (512 GB each)
- **ResourceManager**: YARN job scheduler
- **3 NodeManagers**: YARN task executors

## Quick Start

### Prerequisites
- Docker & Docker Compose installed
- 2+ GB available RAM

### 1. Build the Image

```bash
docker build -t ekinshen/hadoop-with-configuration:3.4.1 .
```

### 2. Start the Cluster

```bash
docker compose up -d
```

Wait for all containers to start:
```bash
docker compose ps
```

### 3. Verify Cluster Health

Check HDFS status:
```bash
docker compose exec namenode hdfs dfsadmin -report
```

Check YARN nodes:
```bash
docker compose exec resourcemanager yarn node -list
```

## Web UIs

- **NameNode (HDFS)**: http://localhost:9870
- **ResourceManager (YARN)**: http://localhost:8088

## File Operations

### Upload File via WebHDFS API

```bash
# Using curl with redirect following
curl -X PUT -T <local-file> "http://localhost:9870/webhdfs/v1/uploads/<filename>?op=CREATE&user.name=root&overwrite=true" -L
```

### Upload via Docker

```bash
docker compose exec namenode bash -c "cat /path/to/file | hdfs dfs -put - /uploads/filename"
```

### List Files

```bash
docker compose exec namenode hdfs dfs -ls /
```

### View File Contents

```bash
docker compose exec namenode hdfs dfs -cat /path/to/file
```

### Create Directory

```bash
docker compose exec namenode hdfs dfs -mkdir -p /mydir
```

### Delete File/Directory

```bash
docker compose exec namenode hdfs dfs -rm -r /path
```

## Common Operations

### Check NameNode Logs

```bash
docker compose logs namenode | tail -50
```

### Check DataNode Logs

```bash
docker compose logs datanode1 | tail -50
```

### Access Container Shell

```bash
docker compose exec namenode bash
```

### Copy File from Container

```bash
docker compose exec namenode hdfs dfs -get /hdfs/path /tmp/local/path
```

### Run Hadoop Command

```bash
docker compose exec namenode hadoop version
docker compose exec namenode hdfs dfs -stat /path
```

## Cluster Management

### Stop All Containers

```bash
docker compose stop
```

### Start Cluster

```bash
docker compose start
```

### Restart Cluster (preserve data)

```bash
docker compose restart
```

### Destroy Cluster (keep volumes)

```bash
docker compose down
```

### Destroy Everything (reset cluster)

```bash
docker compose down -v
```

## Configuration Files

- **core-site.xml**: Hadoop core settings (proxy users, default filesystem)
- **hdfs-site.xml**: HDFS settings (replication, WebHDFS, permissions)
- **yarn-site.xml**: YARN/ResourceManager addressing
- **mapred-site.xml**: MapReduce settings
- **workers**: DataNode hostnames

Edit config files and rebuild:
```bash
docker build -t ekinshen/hadoop-with-configuration:3.4.1 .
docker compose down -v
docker compose up -d
```

## Performance Tuning

### Increase Memory

Edit `docker-compose.yml` and add to each service:
```yaml
environment:
  - HADOOP_HEAPSIZE=4096
```

### Increase Replication Factor

Edit `hdfs-site.xml`:
```xml
<property>
  <name>dfs.replication</name>
  <value>2</value>
</property>
```

## Troubleshooting

### DataNodes Not Registering

Clear volumes and restart:
```bash
docker compose down -v
docker compose up -d
```

### Permission Denied Errors

Permissions are disabled by default (`dfs.permissions.enabled=false`). To re-enable, edit `hdfs-site.xml` and change to `true`, then rebuild.

### Out of Disk Space

Check usage:
```bash
docker system df
```

Clean up:
```bash
docker system prune
```

### Slow Upload/Download

- Increase container memory
- Check network bandwidth
- Verify replication factor (lower = faster)

## API Examples

### List HDFS Directory (JSON)

```bash
curl -s "http://localhost:9870/webhdfs/v1/?op=LISTSTATUS" | jq .
```

### Get File Status

```bash
curl -s "http://localhost:9870/webhdfs/v1/path/to/file?op=GETFILESTATUS" | jq .
```

### Create Empty File

```bash
curl -X PUT "http://localhost:9870/webhdfs/v1/new/file.txt?op=CREATE&user.name=root" -L
```

## Notes

- Permissions checks disabled for development (`dfs.permissions.enabled=false`)
- WebHDFS enabled on port 9870
- HTTP only (no HTTPS)
- All containers run as root user
- Data persists in Docker volumes

## Cleanup

Remove cluster and free resources:
```bash
docker compose down -v
docker rmi ekinshen/hadoop-with-configuration:3.4.1
```
