#!/usr/bin/env bash

# Hadoop Cluster Management Script
# Usage: ./manage_cluster.sh [up|down|logs|status|clean]

set -e

COMPOSE_FILE="docker-compose.yml"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to start cluster
start_cluster() {
    print_info "Starting Hadoop cluster..."
    cd "$PROJECT_DIR"
    docker-compose -f "$COMPOSE_FILE" up -d
    print_success "Cluster started"
    
    print_info "Waiting for NameNode to be ready (60 seconds)..."
    sleep 60
    
    print_info "Waiting for DataNodes to register..."
    sleep 30
    
    print_info "Cluster status:"
    cluster_status
}

# Function to stop cluster
stop_cluster() {
    print_info "Stopping Hadoop cluster..."
    cd "$PROJECT_DIR"
    docker-compose -f "$COMPOSE_FILE" down
    print_success "Cluster stopped"
}

# Function to show logs
show_logs() {
    local service=$1
    if [ -z "$service" ]; then
        print_info "Showing logs from all services..."
        cd "$PROJECT_DIR"
        docker-compose -f "$COMPOSE_FILE" logs -f
    else
        print_info "Showing logs from $service..."
        cd "$PROJECT_DIR"
        docker-compose -f "$COMPOSE_FILE" logs -f "$service"
    fi
}

# Function to show cluster status
cluster_status() {
    print_info "Cluster status:"
    cd "$PROJECT_DIR"
    docker-compose -f "$COMPOSE_FILE" ps
    
    print_info "NameNode Web UI: http://localhost:9870"
    
    # Check if NameNode is healthy
    if curl -s http://localhost:9870 > /dev/null 2>&1; then
        print_success "NameNode is accessible at http://localhost:9870"
    else
        print_warning "NameNode is not yet accessible"
    fi
}

# Function to clean volumes
clean_cluster() {
    print_warning "This will delete all cluster data (volumes)"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        print_info "Removing cluster data..."
        cd "$PROJECT_DIR"
        docker-compose -f "$COMPOSE_FILE" down -v
        print_success "Cluster data cleaned"
    else
        print_info "Operation cancelled"
    fi
}

# Function to check DataNode registration
check_datanodes() {
    print_info "Checking DataNode registration..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker command not found"
        return 1
    fi
    
    if docker exec namenode hdfs dfsadmin -report 2>/dev/null | grep -q "Live datanodes"; then
        docker exec namenode hdfs dfsadmin -report | grep -E "Live datanodes|Hostname" || true
    else
        print_warning "Cannot access NameNode yet, please wait..."
    fi
}

# Main script logic
case "${1:-help}" in
    up)
        start_cluster
        ;;
    down)
        stop_cluster
        ;;
    logs)
        show_logs "${2:-}"
        ;;
    status)
        cluster_status
        ;;
    clean)
        clean_cluster
        ;;
    datanodes)
        check_datanodes
        ;;
    *)
        echo "Usage: $0 {up|down|logs|status|clean|datanodes}"
        echo ""
        echo "Commands:"
        echo "  up        - Start the Hadoop cluster"
        echo "  down      - Stop the Hadoop cluster"
        echo "  logs      - Show logs from all or specific service"
        echo "  status    - Show cluster status"
        echo "  datanodes - Check DataNode registration status"
        echo "  clean     - Clean volumes and stop cluster"
        echo ""
        echo "Examples:"
        echo "  $0 up                 # Start cluster"
        echo "  $0 logs namenode      # Show NameNode logs"
        echo "  $0 status             # Show cluster status"
        exit 1
        ;;
esac
