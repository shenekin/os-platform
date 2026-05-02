#!/bin/bash
# Verify auto-startup configuration

echo "======================================"
echo "AUTO-STARTUP VERIFICATION"
echo "======================================"
echo ""

# Check LaunchAgents are installed
echo "1️⃣  Checking LaunchAgent installation..."
if [ -f "/Users/ekin/Library/LaunchAgents/com.docker.hadoop.cluster.plist" ]; then
    echo "✓ Hadoop LaunchAgent installed"
else
    echo "❌ Hadoop LaunchAgent NOT found"
fi

if [ -f "/Users/ekin/Library/LaunchAgents/com.kind.kubernetes.cluster.plist" ]; then
    echo "✓ Kubernetes LaunchAgent installed"
else
    echo "❌ Kubernetes LaunchAgent NOT found"
fi
echo ""

# Check if LaunchAgents are loaded
echo "2️⃣  Checking LaunchAgent status..."
if launchctl list | grep -q "com.docker.hadoop.cluster"; then
    echo "✓ Hadoop LaunchAgent is LOADED"
else
    echo "⚠️  Hadoop LaunchAgent is NOT loaded"
    echo "   Run: launchctl load /Users/ekin/Library/LaunchAgents/com.docker.hadoop.cluster.plist"
fi

if launchctl list | grep -q "com.kind.kubernetes.cluster"; then
    echo "✓ Kubernetes LaunchAgent is LOADED"
else
    echo "⚠️  Kubernetes LaunchAgent is NOT loaded"
    echo "   Run: launchctl load /Users/ekin/Library/LaunchAgents/com.kind.kubernetes.cluster.plist"
fi
echo ""

# Check startup scripts exist
echo "3️⃣  Checking startup scripts..."
if [ -x "/Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/start_hadoop_cluster.sh" ]; then
    echo "✓ Hadoop startup script exists and is executable"
else
    echo "❌ Hadoop startup script missing or not executable"
fi

if [ -x "/Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/start_kubernetes_cluster.sh" ]; then
    echo "✓ Kubernetes startup script exists and is executable"
else
    echo "❌ Kubernetes startup script missing or not executable"
fi
echo ""

# Check recent logs
echo "4️⃣  Checking recent startup logs..."
if [ -f "/Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/startup.log" ]; then
    LAST_ENTRY=$(tail -1 "/Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/startup.log")
    echo "✓ Hadoop log exists"
    echo "  Last entry: $LAST_ENTRY"
else
    echo "ℹ️  No Hadoop log yet (will be created on first boot)"
fi

if [ -f "/Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/kubernetes_startup.log" ]; then
    LAST_ENTRY=$(tail -1 "/Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/kubernetes_startup.log")
    echo "✓ Kubernetes log exists"
    echo "  Last entry: $LAST_ENTRY"
else
    echo "ℹ️  No Kubernetes log yet (will be created on first boot)"
fi
echo ""

# Check for errors
echo "5️⃣  Checking for startup errors..."
if [ -f "/Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/startup_error.log" ]; then
    ERRORS=$(wc -l < "/Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/startup_error.log")
    if [ "$ERRORS" -gt 0 ]; then
        echo "⚠️  Hadoop startup errors found ($ERRORS lines)"
        tail -3 "/Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/startup_error.log"
    else
        echo "✓ No Hadoop startup errors"
    fi
else
    echo "ℹ️  No error log yet"
fi

if [ -f "/Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/kubernetes_startup_error.log" ]; then
    ERRORS=$(wc -l < "/Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/kubernetes_startup_error.log")
    if [ "$ERRORS" -gt 0 ]; then
        echo "⚠️  Kubernetes startup errors found ($ERRORS lines)"
        tail -3 "/Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/kubernetes_startup_error.log"
    else
        echo "✓ No Kubernetes startup errors"
    fi
else
    echo "ℹ️  No error log yet"
fi
echo ""

echo "======================================"
echo "✅ AUTO-STARTUP VERIFICATION COMPLETE"
echo "======================================"
echo ""
echo "To test auto-startup:"
echo "1. Restart your computer"
echo "2. Wait 2 minutes"
echo "3. Run: ./check_hadoop_health.sh"
echo "4. Run: kubectl cluster-info"
