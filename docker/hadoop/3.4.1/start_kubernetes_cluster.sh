#!/bin/bash
# Auto-start Kubernetes (Kind) cluster on system startup

echo "Starting Kind Kubernetes cluster..."

# Check if Kind is installed
if ! command -v kind &> /dev/null; then
    echo "Kind not installed. Installing..."
    brew install kind
fi

# Wait a bit for system to stabilize
sleep 5

# Check if cluster exists
if ! kind get clusters 2>/dev/null | grep -q "kind"; then
    echo "Creating Kind cluster..."
    kind create cluster --name kind
else
    echo "Kind cluster already exists"
fi

# Export kubeconfig
kind export kubeconfig --name kind 2>/dev/null

echo "✅ Kind cluster ready" >> /Users/ekin/Documents/os-platform/docker/hadoop/3.4.1/kubernetes_startup.log

exit 0
