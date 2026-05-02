#!/bin/bash
# Auto-start Hadoop cluster on system startup
# Install as LaunchAgent for macOS

HADOOP_DIR="/Users/ekin/Documents/os-platform/docker/hadoop/3.4.1"

echo "Starting Hadoop cluster..."

# Wait for Docker to be ready
while ! docker info &>/dev/null; do
    sleep 2
done

echo "Docker is ready. Starting Hadoop..."
cd "$HADOOP_DIR"
docker compose up -d

# Wait for cluster to stabilize
echo "Waiting for cluster to stabilize..."
sleep 60

# Run health check
if "$HADOOP_DIR/check_hadoop_health.sh" &>/dev/null; then
    echo "✅ Hadoop cluster started successfully" >> "$HADOOP_DIR/startup.log"
else
    echo "❌ Hadoop cluster startup failed" >> "$HADOOP_DIR/startup.log"
fi

exit 0
