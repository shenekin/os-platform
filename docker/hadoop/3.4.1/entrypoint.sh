#!/usr/bin/env bash
set -euo pipefail

# Ensure ssh runtime dir exists (required by sshd)
mkdir -p /run/sshd

# Ensure host keys exist
ssh-keygen -A

# Keep root login usable if you rely on it (optional)
chmod 700 /root/.ssh || true
chmod 600 /root/.ssh/authorized_keys 2>/dev/null || true

# Start sshd in foreground (keeps container alive)
exec /usr/sbin/sshd -D -e
