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
