#!/bin/bash
set -euo pipefail

SSH_PUBLIC="$(cat /tmp/env/ssh/host.pub)"
SSH_PRIVATE="$(cat /tmp/env/ssh/host.key)"

mkdir -p /root/.ssh

echo "$SSH_PRIVATE" > "/root/.ssh/id_rsa"
echo "$SSH_PUBLIC" > "/root/.ssh/id_rsa.pub"

chmod 600 "/root/.ssh/id_rsa"
chmod 644 "/root/.ssh/id_rsa.pub"
