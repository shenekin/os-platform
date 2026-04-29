#!/usr/bin/env bash
set -euo pipefail

# ---- SSH setup ----
mkdir -p /run/sshd
ssh-keygen -A

# ---- Hadoop env ----
: "${HADOOP_HOME:=/opt/hadoop-3.4.1}"
export HADOOP_HOME
export HADOOP_CONF_DIR="${HADOOP_HOME}/etc/hadoop"
export PATH="${PATH}:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin"

# Disable niceness changes to avoid:
# "ERROR: Cannot set priority of namenode process ..."
if ! grep -q '^export HADOOP_NICENESS=' "${HADOOP_CONF_DIR}/hadoop-env.sh"; then
  echo 'export HADOOP_NICENESS=0' >> "${HADOOP_CONF_DIR}/hadoop-env.sh"
else
  sed -i 's/^export HADOOP_NICENESS=.*/export HADOOP_NICENESS=0/' "${HADOOP_CONF_DIR}/hadoop-env.sh"
fi

# Ensure Hadoop tmp/log dirs exist and are writable
mkdir -p /tmp/hadoop-root /tmp/hadoop-hadoop
chown -R hadoop:hadoop /tmp/hadoop-hadoop /opt/hadoop-3.4.1

# Format NameNode once (first boot only)
if [ ! -d /tmp/hadoop-hadoop/dfs/name/current ]; then
  sudo -u hadoop "${HADOOP_HOME}/bin/hdfs" namenode -format -force -nonInteractive
fi

# Start SSH daemon
/usr/sbin/sshd

# Start HDFS daemons
sudo -u hadoop "${HADOOP_HOME}/sbin/start-dfs.sh"

# Keep container alive and stream NameNode logs
exec tail -F "${HADOOP_HOME}"/logs/*namenode*.log
