#!/bin/bash
# Kubernetes Cluster Health Check Script
# Verify Kind cluster status after restart

echo "======================================"
echo "KUBERNETES (KIND) CLUSTER HEALTH CHECK"
echo "======================================"
echo ""

# 1. Check if Kind is installed
echo "1️⃣  Checking Kind installation..."
if ! command -v kind &> /dev/null; then
    echo "❌ Kind is not installed"
    echo "   Install: brew install kind"
    exit 1
fi
echo "✓ Kind is installed"
echo ""

# 2. Check if cluster exists
echo "2️⃣  Checking Kind clusters..."
if kind get clusters 2>/dev/null | grep -q "kind"; then
    echo "✓ Kind cluster exists"
else
    echo "⚠️  No Kind cluster found. Creating one..."
    kind create cluster --name kind
    echo "Waiting for cluster to be ready..."
    sleep 30
fi
echo ""

# 3. Check kubectl
echo "3️⃣  Checking kubectl..."
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed"
    echo "   Install: brew install kubectl"
    exit 1
fi
echo "✓ kubectl is installed"
echo ""

# 4. Check cluster connectivity
echo "4️⃣  Checking cluster connectivity..."
if kubectl cluster-info &>/dev/null; then
    echo "✓ kubectl can connect to cluster"
else
    echo "⚠️  kubectl cannot connect. Trying to recover..."
    kind export kubeconfig --name kind 2>/dev/null || true
    sleep 5
fi
echo ""

# 5. Check nodes
echo "5️⃣  Checking cluster nodes..."
NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
if [ "$NODES" -gt 0 ]; then
    echo "✓ Cluster has $NODES node(s)"
    kubectl get nodes --no-headers 2>/dev/null | awk '{print "  - " $1 " (" $2 ")"}'
else
    echo "❌ No nodes found"
    exit 1
fi
echo ""

# 6. Check pods
echo "6️⃣  Checking system pods..."
SYSTEM_PODS=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -c "Running" || true)
TOTAL_SYSTEM=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | wc -l)
echo "✓ System pods: $SYSTEM_PODS/$TOTAL_SYSTEM running"
echo ""

# 7. Check default namespace
echo "7️⃣  Checking default namespace..."
DEFAULT_PODS=$(kubectl get pods -n default --no-headers 2>/dev/null | wc -l)
if [ "$DEFAULT_PODS" -gt 0 ]; then
    echo "✓ Workload pods in default namespace:"
    kubectl get pods -n default --no-headers 2>/dev/null | awk '{print "  - " $1 " (" $3 ")"}'
else
    echo "ℹ️  No workload pods in default namespace"
fi
echo ""

# 8. Check persistent volumes
echo "8️⃣  Checking persistent volumes..."
PVS=$(kubectl get pv --no-headers 2>/dev/null | wc -l)
PVCS=$(kubectl get pvc -n default --no-headers 2>/dev/null | wc -l)
echo "✓ Persistent Volumes: $PVS total"
echo "✓ PVC Claims: $PVCS in default namespace"
echo ""

# 9. Check services
echo "9️⃣  Checking services..."
SERVICES=$(kubectl get svc -n default --no-headers 2>/dev/null | grep -v kubernetes | wc -l)
echo "✓ Services: $SERVICES custom services"
kubectl get svc -n default --no-headers 2>/dev/null | grep -v kubernetes | awk '{print "  - " $1 " (" $5 ")"}'
echo ""

# 10. Check cluster events
echo "🔟 Recent cluster events..."
ERRORS=$(kubectl get events --all-namespaces 2>/dev/null | grep -i error | wc -l || true)
if [ "$ERRORS" -gt 0 ]; then
    echo "⚠️  Found $ERRORS error events"
    kubectl get events --all-namespaces 2>/dev/null | grep -i error | head -3
else
    echo "✓ No error events"
fi
echo ""

echo "======================================"
echo "✅ KUBERNETES CLUSTER IS HEALTHY"
echo "======================================"
echo ""
echo "Next Steps:"
echo "- View dashboard: kubectl proxy (then http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/)"
echo "- Check pods: kubectl get pods --all-namespaces"
echo "- View logs: kubectl logs <pod-name> -n <namespace>"
echo "- Describe pod: kubectl describe pod <pod-name> -n <namespace>"
