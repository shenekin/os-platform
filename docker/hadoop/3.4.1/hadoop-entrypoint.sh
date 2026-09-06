#!/usr/bin/env bash
set -euo pipefail

mkdir -p /run/sshd
ssh-keygen -A 2>/dev/null || true

export JAVA_HOME=/opt/java/openjdk
export HADOOP_HOME=/opt/hadoop-3.4.1
export HADOOP_CONF_DIR="${HADOOP_HOME}/etc/hadoop"
export PATH="${PATH}:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin"

# Fix JAVA_HOME in hadoop-env.sh
sed -i '54s|^# export JAVA_HOME=|export JAVA_HOME=/opt/java/openjdk|' "${HADOOP_CONF_DIR}/hadoop-env.sh" 2>/dev/null || true

# Set HADOOP_NICENESS to suppress warnings
if ! grep -q '^export HADOOP_NICENESS=' "${HADOOP_CONF_DIR}/hadoop-env.sh"; then
  echo 'export HADOOP_NICENESS=0' >> "${HADOOP_CONF_DIR}/hadoop-env.sh"
fi

# Temporarily backup original config files
CORE_SITE="${HADOOP_CONF_DIR}/core-site.xml"
HDFS_SITE="${HADOOP_CONF_DIR}/hdfs-site.xml"

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

# Create log directory
LOG_DIR="/var/log/hadoop"
mkdir -p "$LOG_DIR"
chown -R hadoop:hadoop "$LOG_DIR" 2>/dev/null || true
chmod 755 "$LOG_DIR" 2>/dev/null || true

# Create tmp directories for Hadoop
mkdir -p /tmp/hadoop-root /tmp/hadoop-hadoop 2>/dev/null || true
chown -R hadoop:hadoop /tmp/hadoop-hadoop 2>/dev/null || true

# Start SSH daemon
/usr/sbin/sshd

# Format NameNode on first startup
if [ ! -d "${NAMENODE_DIR}/current" ]; then
  echo "Formatting NameNode..."
  sudo -u hadoop "${HADOOP_HOME}/bin/hdfs" namenode -format -force -nonInteractive 2>&1 | tail -10 || true
  sleep 2
fi

# Start Hadoop services based on node type
case "${HADOOP_NODE_TYPE:-namenode}" in
  namenode)
    echo "Starting Hadoop NameNode..."
    sudo -u hadoop "${HADOOP_HOME}/bin/hdfs" namenode &
    NAMENODE_PID=$!
    sleep 5
    
    # Tail the logs
    tail -F "${HADOOP_HOME}"/logs/*namenode*.log 2>/dev/null &
    TAIL_PID=$!
    
    # Wait for the main process
    wait $NAMENODE_PID
    ;;
    
  datanode)
    echo "Waiting for NameNode to be ready..."
    sleep 15
    
    echo "Starting Hadoop DataNode..."
    sudo -u hadoop "${HADOOP_HOME}/bin/hdfs" datanode &
    DATANODE_PID=$!
    
    # Tail the logs
    tail -F "${HADOOP_HOME}"/logs/*datanode*.log 2>/dev/null &
    TAIL_PID=$!
    
    # Wait for the main process
    wait $DATANODE_PID
    ;;
    
  *)
    echo "Unknown node type: ${HADOOP_NODE_TYPE}"
    sleep infinity
    ;;
esac
