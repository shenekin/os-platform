## Hadoop 3.4.1 Docker Cluster Setup Guide

### Overview
This Docker Compose setup provides a fully distributed Hadoop cluster with:
- 1 NameNode
- 3 DataNodes (datanode1, datanode2, datanode3)
- Custom bridge network for inter-container communication
- Persistent volumes for data storage
- Health checks and automatic restart policies

### Network Architecture
- **Network**: `hadoop-network` (bridge driver)
- **Subnet**: 172.28.0.0/16
- **Container Communication**: Services communicate using container hostnames (e.g., `namenode:8020`)

### Port Mappings

#### NameNode (namenode)
- `8020:8020` - HDFS NameNode RPC
- `9870:9870` - NameNode Web UI

#### DataNode1 (datanode1)
- `9866:9866` - DataNode Data Transfer
- `9864:9864` - DataNode HTTP
- `9867:9867` - DataNode IPC

#### DataNode2 (datanode2)
- `9876:9866` - DataNode Data Transfer
- `9874:9864` - DataNode HTTP
- `9877:9867` - DataNode IPC

#### DataNode3 (datanode3)
- `9886:9866` - DataNode Data Transfer
- `9884:9864` - DataNode HTTP
- `9887:9867` - DataNode IPC

### Configuration Files

#### core-site.xml
- Default FileSystem: `hdfs://namenode:8020`
- Temporary directory: `/tmp/hadoop-${user.name}`
- Buffer size: 128KB

#### hdfs-site.xml
- Replication factor: 3
- NameNode RPC: `namenode:8020`
- NameNode HTTP: `namenode:9870`
- DataNode data directory: `/hadoop/dfs/data`
- NameNode name directory: `/hadoop/dfs/name`
- Heartbeat interval: 3 seconds
- DataNode hostname resolution enabled

### Quick Start

#### 1. Start the Cluster
```bash
docker-compose up -d
```

Or use the management script:
```bash
./manage_cluster.sh up
```

#### 2. Wait for Services to Start
The cluster takes about 60-90 seconds to fully initialize:
- NameNode formatting and startup: ~30 seconds
- DataNode registration: ~30-60 seconds

#### 3. Verify Cluster Status
```bash
docker-compose ps
```

Or:
```bash
./manage_cluster.sh status
```

#### 4. Access NameNode Web UI
Open your browser and navigate to:
```
http://localhost:9870
```

You should see:
- Live DataNodes count (should be 3)
- DataNode details (datanode1, datanode2, datanode3)
- Storage information

#### 5. Check DataNode Registration
```bash
./manage_cluster.sh datanodes
```

Or manually:
```bash
docker exec namenode hdfs dfsadmin -report
```

### Management Commands

#### Start Cluster
```bash
./manage_cluster.sh up
```

#### Stop Cluster
```bash
./manage_cluster.sh down
```

#### View Logs
Show all logs:
```bash
./manage_cluster.sh logs
```

Show specific service logs:
```bash
./manage_cluster.sh logs namenode
./manage_cluster.sh logs datanode1
```

Real-time logs with Docker Compose:
```bash
docker-compose logs -f namenode
docker-compose logs -f datanode1
```

#### Check Cluster Status
```bash
./manage_cluster.sh status
```

#### Clean All Data (Reset Cluster)
```bash
./manage_cluster.sh clean
```

This removes all volumes and containers, allowing a fresh cluster start.

### Hadoop Commands

#### Access NameNode Container
```bash
docker exec -it namenode bash
```

#### List HDFS Files
```bash
docker exec namenode hdfs dfs -ls /
```

#### Create HDFS Directory
```bash
docker exec namenode hdfs dfs -mkdir -p /user/hadoop
```

#### Put File into HDFS
```bash
docker exec namenode hdfs dfs -put /path/to/file /user/hadoop/
```

#### Get File from HDFS
```bash
docker exec namenode hdfs dfs -get /user/hadoop/filename /path/to/local/
```

#### Check DataNode Report
```bash
docker exec namenode hdfs dfsadmin -report
```

#### Check Cluster Health
```bash
docker exec namenode hdfs fsck /
```

#### Format NameNode (WARNING: Deletes All Data)
```bash
docker exec -u hadoop namenode hdfs namenode -format -force
```

### Common Issues and Solutions

#### Issue: DataNodes not registering with NameNode
**Symptoms**: NameNode Web UI shows 0 live DataNodes

**Solutions**:
1. Wait longer (can take 60+ seconds)
2. Check DataNode logs:
   ```bash
   docker logs datanode1
   ```
3. Verify network connectivity:
   ```bash
   docker network inspect hadoop-network
   ```
4. Restart DataNodes:
   ```bash
   docker-compose restart datanode1 datanode2 datanode3
   ```

#### Issue: Port conflicts
**Symptoms**: Container fails to start, port already in use

**Solutions**:
1. Stop the cluster completely:
   ```bash
   docker-compose down
   ```
2. Check if processes are using ports:
   ```bash
   lsof -i :8020
   lsof -i :9870
   ```
3. Modify port mappings in docker-compose.yml if needed

#### Issue: NameNode fails to format
**Symptoms**: NameNode exits immediately

**Solutions**:
1. Clean cluster data:
   ```bash
   ./manage_cluster.sh clean
   ```
2. Restart:
   ```bash
   ./manage_cluster.sh up
   ```
3. Check logs:
   ```bash
   docker logs namenode
   ```

#### Issue: Out of disk space or permission errors
**Solutions**:
1. Clean up Docker system:
   ```bash
   docker system prune -a
   docker volume prune
   ```
2. Check volumes:
   ```bash
   docker volume ls
   docker volume inspect hadoop_namenode-data
   ```

### Volume Management

#### List Volumes
```bash
docker volume ls | grep hadoop
```

#### Inspect Volume Location
```bash
docker volume inspect hadoop_namenode-data
```

#### Manual Volume Cleanup
```bash
docker volume rm hadoop_namenode-data hadoop_datanode1-data hadoop_datanode2-data hadoop_datanode3-data hadoop_hadoop-logs
```

### Performance Tuning

#### Modify Configuration Files
Edit `conf/hdfs-site.xml` or `conf/core-site.xml`, then restart:
```bash
docker-compose restart
```

#### Increase Resource Limits
Edit docker-compose.yml and add resource constraints:
```yaml
services:
  namenode:
    deploy:
      resources:
        limits:
          memory: 4G
        reservations:
          memory: 2G
```

### Backup and Recovery

#### Backup NameNode Data
```bash
docker run --rm -v hadoop_namenode-data:/data -v $(pwd):/backup alpine tar czf /backup/namenode-backup.tar.gz -C /data .
```

#### Backup All Data
```bash
docker run --rm -v hadoop_namenode-data:/namenode -v hadoop_datanode1-data:/datanode1 -v hadoop_datanode2-data:/datanode2 -v hadoop_datanode3-data:/datanode3 -v $(pwd):/backup alpine tar czf /backup/hadoop-full-backup.tar.gz -C / namenode datanode1 datanode2 datanode3
```

### Monitoring and Debugging

#### Real-time Container Monitoring
```bash
docker stats
```

#### Check Container Events
```bash
docker events --filter type=container
```

#### View Container Environment Variables
```bash
docker inspect namenode --format='{{json .Config.Env}}' | jq .
```

#### Network Connectivity Test
```bash
docker exec namenode ping datanode1
docker exec namenode ping datanode2
docker exec namenode ping datanode3
```

### Clean Shutdown
```bash
docker-compose down
```

This stops all containers but preserves data in volumes.

### Full Reset
```bash
./manage_cluster.sh clean
```

Or manually:
```bash
docker-compose down -v
```

This removes containers and all data volumes.

### Troubleshooting Commands Quick Reference
```bash
# View all running containers
docker-compose ps

# View specific logs
docker-compose logs -f namenode
docker logs -f datanode1

# Access container shell
docker exec -it namenode bash
docker exec -it datanode1 bash

# Check network
docker network inspect hadoop-network

# Verify services are running
curl http://localhost:9870
curl http://localhost:9870/jmx

# Check HDFS status
docker exec namenode hdfs dfsadmin -report

# Full system health check
docker exec namenode hdfs fsck /
```

### Support and Further Information
- Hadoop Documentation: https://hadoop.apache.org/docs/
- Docker Compose Documentation: https://docs.docker.com/compose/
- HDFS Architecture: https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/HdfsDesign.html
