#!/bin/bash
# Add all hosts to /etc/hosts for name resolution in host network mode
cat >> /etc/hosts <<EOF
127.0.0.1 namenode
127.0.0.1 resourcemanager
127.0.0.1 datanode1
127.0.0.1 datanode2
127.0.0.1 datanode3
127.0.0.1 nodemanager1
127.0.0.1 nodemanager2
127.0.0.1 nodemanager3
EOF
