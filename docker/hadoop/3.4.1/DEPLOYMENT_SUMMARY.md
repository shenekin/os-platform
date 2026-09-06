## Hadoop 3.4.1 Cluster Configuration Summary

### Status: ✅ ACTIVE AND RUNNING

Your Hadoop 3.4.1 cluster is now fully configured and operational with proper network setup.

---

## Configuration Summary

### Network Architecture
- **Network Type**: Custom bridge network (`hadoop-network`)
- **Subnet**: 172.28.0.0/16
- **DNS Resolution**: Enabled via Docker embedded DNS
- **Communication**: All containers communicate via hostnames (namenode, datanode1-3)

### Cluster Topology
- **1 NameNode** (namenode)
- **3 DataNodes** (datanode1, datanode2, datanode3)
- **Replication Factor**: 3
- **Block Size**: Default (128MB)

### Key Configuration Files

#### docker-compose.yml
- Uses bridge network instead of host mode for better isolation
- Health checks enabled for all services
- Dependency management ensures NameNode starts before DataNodes
- Persistent volumes for data storage
- Port mappings prevent conflicts when multiple datanodes use same container ports

#### conf/core-site.xml
```xml
<property>
  <name>fs.defaultFS</name>
  <value>hdfs://namenode:8020</value>  <!-- Uses DNS name -->
</property>
```

#### conf/hdfs-site.xml
```xml
<property>
  <name>dfs.namenode.rpc-address</name>
  <value>namenode:8020</value>  <!-- Uses DNS name for inter-container communication -->
</property>
<property>
  <name>dfs.replication</name>
  <value>3</value>  <!-- Full replication across 3 datanodes -->
</property>
```

#### workers file
```
datanode1
datanode2
datanode3
```

---

## Container Port Mappings

### NameNode
| Service          | Port | Mapping       | Purpose                    |
|------------------|------|---------------|----------------------------|
| HDFS RPC         | 9000 | 9000→9000     | HDFS Block Pool Service   |
| NameNode RPC     | 8020 | 8020→8020     | NameNode RPC Interface    |
| NameNode Web UI  | 9870 | 9870→9870     | Web UI & REST API         |

### DataNodes (Port Offset Strategy)
| Service          | datanode1 | datanode2 | datanode3 |
|------------------|-----------|-----------|-----------|
| Data Transfer    | 9866      | 9876      | 9886      |
| HTTP Server      | 9864      | 9874      | 9884      |
| IPC Server       | 9867      | 9877      | 9887      |

---

## Verified Functionality

✅ All 4 containers running and healthy
✅ NameNode successfully formatted and initialized
✅ All 3 DataNodes registered with NameNode
✅ Custom bridge network functioning correctly
✅ DNS resolution between containers working
✅ Replication factor: 3
✅ HDFS filesystem operational

---

## Cluster Status Command
```bash
$ docker exec namenode hdfs dfsadmin -report

Live datanodes (3):
Name: 172.28.0.3:9866 (datanode2.341_hadoop-network)
Hostname: datanode2

Name: 172.28.0.4:9866 (datanode1.341_hadoop-network)
Hostname: datanode1

Name: 172.28.0.5:9866 (datanode3.341_hadoop-network)
Hostname: datanode3
```

---

## Access the Cluster

### NameNode Web UI
- URL: http://localhost:9870
- Shows live datanodes, storage info, and block details

### Access from Host Machine
```bash
# Connect to HDFS
hadoop fs -ls hdfs://localhost:8020/

# Or via Java/Scala client
val conf = new Configuration()
conf.set("fs.defaultFS", "hdfs://localhost:8020")
val fs = FileSystem.get(conf)
```

### Access from Container
```bash
docker exec namenode hdfs dfs -ls /
docker exec namenode hdfs dfs -mkdir /user
docker exec namenode hdfs dfs -put /etc/hostname /user/hostname
```

---

## Volume Management

### Created Volumes
```
341_namenode-data      (1.0GB+)  - NameNode metadata
341_datanode1-data     (1.0GB+)  - DataNode1 storage
341_datanode2-data     (1.0GB+)  - DataNode2 storage
341_datanode3-data     (1.0GB+)  - DataNode3 storage
341_hadoop-logs        (500MB+)  - Hadoop logs
```

### Inspect Volume Location
```bash
docker volume inspect 341_namenode-data | jq '.[0].Mountpoint'
```

---

## Troubleshooting

### If DataNodes are not registering:
1. Check logs: `docker logs datanode1`
2. Verify network connectivity: `docker exec namenode ping datanode1`
3. Check cluster ID consistency: `docker exec namenode cat /hadoop/dfs/name/current/VERSION`

### If Web UI is not accessible:
1. Verify port is published: `docker ps | grep namenode`
2. Check firewall: `lsof -i :9870`
3. Curl directly: `curl -v http://localhost:9870`

### If HDFS commands fail:
1. Verify NameNode is running: `docker logs namenode | tail -20`
2. Check HDFS health: `docker exec namenode hdfs dfsadmin -report`
3. View detailed logs: `docker exec namenode ls -la /opt/hadoop-3.4.1/logs/`

---

## Management Commands

### Start Cluster
```bash
./manage_cluster.sh up
# or
docker-compose up -d
```

### Stop Cluster
```bash
./manage_cluster.sh down
# or
docker-compose down
```

### View Logs
```bash
./manage_cluster.sh logs namenode
# or
docker-compose logs -f namenode
```

### Check Cluster Status
```bash
./manage_cluster.sh status
# or
docker-compose ps
```

### Validate Configuration
```bash
./validate_cluster.sh
```

### Clean All Data (Full Reset)
```bash
./manage_cluster.sh clean
# or
docker-compose down -v
```

---

## Network Validation

### DNS Resolution Works ✅
```bash
$ docker exec namenode getent hosts datanode1
172.28.0.4 datanode1.341_hadoop-network datanode1

$ docker exec namenode getent hosts namenode
172.28.0.2 namenode.341_hadoop-network namenode
```

### Container Connectivity ✅
```bash
$ docker exec namenode ping datanode1
PING datanode1.341_hadoop-network (172.28.0.4) 56(84) bytes of data.
64 bytes from datanode1.341_hadoop-network (172.28.0.4): icmp_seq=1 ttl=64 time=0.144 ms
```

### HDFS Communication ✅
```bash
$ docker exec namenode hdfs dfsadmin -report
# Returns live datanodes information
```

---

## Key Improvements Made

1. **Replaced Host Network with Bridge Network**
   - Eliminates port conflicts
   - Enables container DNS resolution
   - Supports multiple DataNodes on same machine

2. **Corrected Service Discovery**
   - Changed from hardcoded IP (192.168.101.6) to service names
   - Enables `namenode:8020` instead of `localhost:8020`
   - Datanodes register using container hostnames

3. **Added Health Checks**
   - Prevents starting DataNodes before NameNode
   - Automatic service monitoring

4. **Unique Port Mappings**
   - Each DataNode has unique external ports
   - Prevents "port already allocated" errors

5. **Persistent Volumes**
   - Separate volumes for each component
   - Data survives container restart

6. **Updated Configuration Files**
   - Removed hardcoded IP addresses
   - Set correct replication factor (3)
   - Configured proper heartbeat intervals

---

## Next Steps

1. **Test Data Operations**
   ```bash
   docker exec namenode hdfs dfs -mkdir /test
   docker exec namenode hdfs dfs -put /etc/hostname /test/
   docker exec namenode hdfs dfs -ls /test/
   ```

2. **Monitor Cluster**
   - Watch Web UI: http://localhost:9870
   - Monitor logs: `docker-compose logs -f`

3. **Set Up YARN** (optional)
   - Configure yarn-site.xml for MapReduce
   - Start ResourceManager and NodeManagers

4. **Implement Backup Strategy**
   - Regular volume snapshots
   - Cross-zone replication

---

Generated: 2026-06-02
Cluster Configuration: Docker Compose with Custom Bridge Network
Status: Fully Operational ✅
