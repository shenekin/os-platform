# Auto-Startup Configuration Guide

## ✅ Automatic Cluster Startup (macOS)

Your Hadoop and Kubernetes clusters are now configured to start automatically when your system boots.

---

## What Was Set Up

### 1. Hadoop Cluster Auto-Startup
- **LaunchAgent:** `com.docker.hadoop.cluster.plist`
- **Location:** `/Users/ekin/Library/LaunchAgents/com.docker.hadoop.cluster.plist`
- **Startup Script:** `start_hadoop_cluster.sh`
- **Logs:** `startup.log`, `startup_error.log`

**How it works:**
1. Waits for Docker to start
2. Runs `docker compose up -d` in Hadoop directory
3. Waits 60 seconds for cluster to stabilize
4. Runs health check verification
5. Logs results to `startup.log`

### 2. Kubernetes Cluster Auto-Startup
- **LaunchAgent:** `com.kind.kubernetes.cluster.plist`
- **Location:** `/Users/ekin/Library/LaunchAgents/com.kind.kubernetes.cluster.plist`
- **Startup Script:** `start_kubernetes_cluster.sh`
- **Logs:** `kubernetes_startup.log`, `kubernetes_startup_error.log`

**How it works:**
1. Checks if Kind is installed (installs if missing)
2. Creates Kind cluster if it doesn't exist
3. Exports kubeconfig for kubectl access
4. Logs results to `kubernetes_startup.log`

---

## Verify Auto-Startup Is Working

### Check LaunchAgent Status
```bash
launchctl list | grep -E "hadoop|kubernetes"
```

Expected output:
```
- 0  com.docker.hadoop.cluster
- 0  com.kind.kubernetes.cluster
```

### Check Startup Logs
```bash
# Hadoop startup log
tail -20 /Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/startup.log

# Kubernetes startup log
tail -20 /Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/kubernetes_startup.log

# Check for errors
tail -20 /Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/startup_error.log
tail -20 /Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/kubernetes_startup_error.log
```

### Manual Test
```bash
# Unload and reload to test
launchctl unload /Users/ekin/Library/LaunchAgents/com.docker.hadoop.cluster.plist
sleep 3
launchctl load /Users/ekin/Library/LaunchAgents/com.docker.hadoop.cluster.plist

# Check if it started
sleep 60
docker compose -f /Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/docker-compose.yml ps
```

---

## Startup Timeline After System Boot

1. **0 seconds:** System boots, LaunchAgent fires
2. **5-10 seconds:** Docker starts (if not already running)
3. **10-20 seconds:** Hadoop containers start
4. **30-60 seconds:** Cluster stabilizes, health check runs
5. **60 seconds:** Hadoop cluster ready for use
6. **60-120 seconds:** Kubernetes Kind cluster starts
7. **120 seconds:** Both clusters ready

**Total time to full readiness: ~2 minutes**

---

## Access Clusters After Boot

### Hadoop
```bash
# Check status
cd /Users/ekin/Documents/os-platform/docker/hadoop/3.4.1
./check_hadoop_health.sh

# Access web UIs
open http://localhost:9870      # NameNode
open http://localhost:8088      # ResourceManager
```

### Kubernetes
```bash
# Check status
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces

# View kubeconfig
kubectl config current-context
```

---

## Management Commands

### Start/Stop Hadoop Cluster

**Manually start:**
```bash
cd /Users/ekin/Documents/os-platform/docker/hadoop/3.4.1
docker compose up -d
```

**Manually stop:**
```bash
cd /Users/ekin/Documents/os-platform/docker/hadoop/3.4.1
docker compose down
```

**Restart:**
```bash
cd /Users/ekin/Documents/os-platform/docker/hadoop/3.4.1
docker compose restart
```

### Start/Stop Kubernetes Cluster

**Manually start:**
```bash
kind create cluster --name kind
```

**Manually stop:**
```bash
kind delete cluster --name kind
```

---

## Disable Auto-Startup

### Temporarily Disable Hadoop Auto-Startup
```bash
launchctl unload /Users/ekin/Library/LaunchAgents/com.docker.hadoop.cluster.plist
```

### Temporarily Disable Kubernetes Auto-Startup
```bash
launchctl unload /Users/ekin/Library/LaunchAgents/com.kind.kubernetes.cluster.plist
```

### Re-enable After Disabling
```bash
launchctl load /Users/ekin/Library/LaunchAgents/com.docker.hadoop.cluster.plist
launchctl load /Users/ekin/Library/LaunchAgents/com.kind.kubernetes.cluster.plist
```

### Permanently Remove Auto-Startup
```bash
# Remove LaunchAgents
rm /Users/ekin/Library/LaunchAgents/com.docker.hadoop.cluster.plist
rm /Users/ekin/Library/LaunchAgents/com.kind.kubernetes.cluster.plist

# Unload if already running
launchctl unload /Users/ekin/Library/LaunchAgents/com.docker.hadoop.cluster.plist
launchctl unload /Users/ekin/Library/LaunchAgents/com.kind.kubernetes.cluster.plist
```

---

## Troubleshooting Auto-Startup

### Clusters Not Starting After Boot

**Check if LaunchAgent is loaded:**
```bash
launchctl list | grep hadoop
```

**If not loaded, reload:**
```bash
launchctl load /Users/ekin/Library/LaunchAgents/com.docker.hadoop.cluster.plist
```

**Check startup errors:**
```bash
tail -50 /Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/startup_error.log
```

### Docker Not Starting in Time

The startup scripts wait for Docker automatically, but if you see connection errors:

1. Start Docker Desktop manually first
2. Wait 30 seconds
3. Hadoop should start automatically
4. Or manually: `cd /Users/ekin/Documents/os-platform/docker/hadoop/3.4.1 && docker compose up -d`

### Port Conflicts

If ports are already in use:
```bash
# Find what's using port 9870
lsof -i :9870

# Kill if needed
kill -9 <PID>

# Or change ports in docker-compose.yml and rebuild
```

### Permission Errors

If you get permission denied errors:
```bash
# Make scripts executable
chmod +x /Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/start_hadoop_cluster.sh
chmod +x /Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/start_kubernetes_cluster.sh

# Reload LaunchAgents
launchctl unload /Users/ekin/Library/LaunchAgents/com.docker.hadoop.cluster.plist
launchctl load /Users/ekin/Library/LaunchAgents/com.docker.hadoop.cluster.plist
```

---

## Files Created

```
/Users/ekin/Library/LaunchAgents/
├── com.docker.hadoop.cluster.plist       ← Hadoop LaunchAgent
└── com.kind.kubernetes.cluster.plist     ← Kubernetes LaunchAgent

/Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/
├── start_hadoop_cluster.sh               ← Hadoop startup script
├── start_kubernetes_cluster.sh           ← Kubernetes startup script
├── startup.log                           ← Hadoop startup log
├── startup_error.log                     ← Hadoop startup errors
├── kubernetes_startup.log                ← Kubernetes startup log
└── kubernetes_startup_error.log          ← Kubernetes startup errors
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Check auto-startup status | `launchctl list \| grep -E "hadoop\|kubernetes"` |
| View Hadoop startup log | `tail -20 ~/Documents/os-platform/docker/hadoop/3.4.1/startup.log` |
| View K8s startup log | `tail -20 ~/Documents/os-platform/docker/hadoop/3.4.1/kubernetes_startup.log` |
| Disable Hadoop auto-start | `launchctl unload ~/Library/LaunchAgents/com.docker.hadoop.cluster.plist` |
| Disable K8s auto-start | `launchctl unload ~/Library/LaunchAgents/com.kind.kubernetes.cluster.plist` |
| Manually start Hadoop | `cd ~/Documents/os-platform/docker/hadoop/3.4.1 && docker compose up -d` |
| Manually start K8s | `kind create cluster --name kind` |
| Check Hadoop health | `cd ~/Documents/os-platform/docker/hadoop/3.4.1 && ./check_hadoop_health.sh` |
| Check K8s status | `kubectl cluster-info` |

---

## Important Notes

- **Docker Desktop must be installed** - LaunchAgent cannot start Docker from scratch; it must be already installed
- **Both clusters start at system boot** - If you don't want this, use the disable commands above
- **Startup takes ~2 minutes** - Allow time for both clusters to fully initialize
- **Logs are available** - Check `startup.log` and `kubernetes_startup.log` for debugging
- **Manual management still works** - You can always start/stop clusters manually with docker compose

---

## Next Steps

1. ✅ Auto-startup configured
2. **Restart your computer** to test
3. Wait 2 minutes after boot
4. Run: `cd /Users/ekin/Documents/os-platform/docker/hadoop/3.4.1 && ./check_hadoop_health.sh`
5. Verify both clusters start automatically

**After restart, your clusters will be ready to use without manual intervention!**
