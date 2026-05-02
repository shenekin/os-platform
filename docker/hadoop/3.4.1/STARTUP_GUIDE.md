# Cluster Startup & Health Check Guide

## After Computer Restart or Cluster Restart

### Quick Start (30 seconds)

```bash
# 1. Start Hadoop cluster
cd /Users/ekin/Documents/os-platform/docker/hadoop/3.4.1
docker compose up -d

# 2. Run health check
./check_hadoop_health.sh

# 3. If using Kubernetes, start Kind cluster
kind create cluster --name kind
./check_kubernetes_health.sh
```

---

## Hadoop Cluster Health Check

### Option 1: Automated Script (Recommended)
```bash
cd /Users/ekin/Documents/os-platform/docker/hadoop/3.4.1
./check_hadoop_health.sh
```

### Option 2: Manual Commands

**Check if cluster is running:**
```bash
cd /Users/ekin/Documents/os-platform/docker/hadoop/3.4.1
docker compose ps
```
Expected: 8 containers running (namenode, 3 datanodes, resourcemanager, 3 nodemanagers)

**Check NameNode health:**
```bash
docker compose exec namenode hdfs dfsadmin -report
```
Look for: "Live datanodes (3)" and no error messages

**Check YARN health:**
```bash
docker compose exec resourcemanager yarn node -list
```
Look for: "Total Nodes:3" and all "RUNNING" state

**Check HDFS filesystem:**
```bash
docker compose exec namenode hdfs fsck /
```
Look for: "The filesystem under path '/' is HEALTHY"

**Check web UIs:**
- NameNode: http://localhost:9870
- ResourceManager: http://localhost:8088
- Both should load without errors

### What to Check After Restart

| Component | Command | Expected Result |
|-----------|---------|-----------------|
| Docker | `docker ps` | All containers "Up" |
| NameNode | `hdfs dfsadmin -report` | "Configured Capacity" shown |
| DataNodes | `hdfs dfsadmin -report` | "Live datanodes (3)" |
| YARN | `yarn node -list` | "Total Nodes:3" |
| HDFS Health | `hdfs fsck /` | "HEALTHY" status |
| Web UIs | Browser to :9870 & :8088 | Pages load |

---

## Kubernetes (Kind) Cluster Health Check

### Option 1: Automated Script (if Kind is installed)
```bash
./check_kubernetes_health_check.sh
```

### Option 2: Manual Commands

**Check if Kind is installed:**
```bash
kind --version
```

**Create or start Kind cluster:**
```bash
kind create cluster --name kind
# or if already exists, get kubeconfig
kind export kubeconfig --name kind
```

**Check cluster status:**
```bash
kubectl cluster-info
```

**Check nodes:**
```bash
kubectl get nodes
```
Expected: 1 node (kind-control-plane) in "Ready" state

**Check system pods:**
```bash
kubectl get pods -n kube-system
```
Expected: All CoreDNS, etcd, kube-proxy, etc. in "Running" state

**Check custom workload:**
```bash
kubectl get pods -n default
kubectl get svc -n default
```

**Check persistent volumes:**
```bash
kubectl get pv
kubectl get pvc -n default
```

---

## Troubleshooting

### Hadoop Cluster Won't Start

```bash
# 1. Check if containers exist
docker ps -a

# 2. Check logs
docker compose logs namenode | tail -50
docker compose logs datanode1 | tail -50

# 3. If stuck, reset cluster
docker compose down -v
docker compose up -d
./check_hadoop_health.sh
```

### DataNodes Not Registering

```bash
# Check for clusterID mismatch
docker compose logs datanode1 | grep clusterID

# Fix: Remove volumes and restart
docker compose down -v
docker compose up -d
sleep 30
./check_hadoop_health.sh
```

### YARN Nodes Not Showing

```bash
# Check ResourceManager logs
docker compose logs resourcemanager | tail -50

# Verify NodeManager is running
docker compose logs nodemanager1 | tail -20

# Restart YARN
docker compose restart resourcemanager nodemanager1 nodemanager2 nodemanager3
sleep 10
./check_hadoop_health.sh
```

### Port Already in Use

```bash
# Find what's using port 9870
lsof -i :9870

# Kill process or use different port
# Edit docker-compose.yml ports section
docker compose down
docker compose up -d
```

### Kubernetes Won't Connect

```bash
# Export kubeconfig
kind export kubeconfig --name kind

# Test connection
kubectl cluster-info

# View contexts
kubectl config get-contexts

# Switch context if needed
kubectl config use-context kind-kind
```

---

## Essential Ports

**Hadoop Cluster:**
- 9870: NameNode Web UI
- 8088: ResourceManager Web UI
- 9000: HDFS RPC (Java clients)
- 8020: HDFS HTTP endpoint
- 9866: DataNode service

**Kubernetes:**
- 6443: API Server
- 8001: kubectl proxy (when running)

---

## Quick Verification Steps

### 1-Minute Check
```bash
# Terminal 1
cd /Users/ekin/Documents/os-platform/docker/hadoop/3.4.1
./check_hadoop_health.sh

# Check result: Should see ✅ at end
```

### 5-Minute Check
```bash
# Check all Hadoop endpoints
docker compose exec namenode hdfs dfs -ls /
docker compose exec namenode hdfs dfsadmin -report | grep "Live datanodes"
docker compose exec resourcemanager yarn node -list

# Open web UIs
open http://localhost:9870
open http://localhost:8088
```

### Test Data Upload
```bash
# Upload small test file
docker compose exec namenode bash -c \
  "echo 'Test' > /tmp/test.txt && hdfs dfs -put /tmp/test.txt /test_file.txt"

# Verify
docker compose exec namenode hdfs dfs -cat /test_file.txt
```

---

## Health Check Results

### ✅ Healthy Cluster Signs
- All 8 Hadoop containers "Up"
- NameNode responds to `hdfs dfsadmin -report`
- 3 DataNodes showing as "Live"
- 3 NodeManagers in "RUNNING" state
- HDFS fsck shows "HEALTHY"
- Web UIs load without errors
- No ERROR or EXCEPTION in logs

### ⚠️ Warning Signs
- Containers restarting frequently
- DataNodes showing as "Dead" 
- Under-replicated blocks in HDFS
- Web UIs timing out
- Connection refused errors

### ❌ Critical Issues
- Containers won't start
- All DataNodes missing
- ResourceManager not responding
- HDFS fsck shows "CORRUPT"
- Logs show "OutOfMemory" or Java exceptions

---

## Daily Maintenance

**After computer restart:**
1. Run: `./check_hadoop_health.sh`
2. Wait 30 seconds for result
3. If ✅, cluster is ready for use
4. If ❌, check troubleshooting section

**Weekly (Optional):**
```bash
# Clean unused Docker data
docker system prune -f

# Check disk usage
docker system df
```

**Monthly (Optional):**
```bash
# Backup HDFS data
docker compose exec namenode hdfs dfs -get / /backup/

# Verify all test files deleted
docker compose exec namenode hdfs dfs -du -h /
```

---

## File Locations

```
/Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/
├── check_hadoop_health.sh          (✅ Run this after restart)
├── check_kubernetes_health.sh       (✅ Run this for Kubernetes)
├── docker-compose.yml              (Cluster configuration)
├── Dockerfile                       (Image build)
├── README.md                        (Full documentation)
└── *.xml                            (Config files)
```

---

## Commands Cheat Sheet

```bash
# Hadoop
docker compose up -d                              # Start cluster
docker compose down                               # Stop cluster
docker compose logs namenode                      # View namenode logs
docker compose exec namenode hdfs dfs -ls /       # List HDFS files
docker compose exec namenode hdfs dfs -put <file> /path  # Upload file

# Kubernetes
kind create cluster --name kind                   # Create Kind cluster
kind delete cluster --name kind                   # Delete Kind cluster
kubectl get nodes                                 # List nodes
kubectl get pods --all-namespaces                 # List all pods
kubectl describe pod <name>                       # Pod details
kubectl logs <pod-name>                           # Pod logs

# Docker
docker system df                                  # Show Docker disk usage
docker system prune -a -f                         # Clean Docker
docker ps                                         # List running containers
```

---

**Last Updated:** 2026-04-30  
**Hadoop Version:** 3.4.1  
**Docker Compose:** v3.9  
**Kind Kubernetes:** Latest  
