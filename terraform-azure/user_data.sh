#!/bin/bash
#
# VM boot-time bootstrap script — FormFlow capstone (Azure version)
# Runs automatically the FIRST time the VM boots (Azure calls this
# "custom_data" / cloud-init). Installs Docker + Docker Compose on Ubuntu
# so the VM is ready to `docker compose up` as soon as it exists.
# Safe to re-run: skips work already done via a marker file.

set -euo pipefail

exec > >(tee /var/log/user-data.log | logger -t user-data) 2>&1

export DEBIAN_FRONTEND=noninteractive

MARKER=/opt/capstone/.bootstrapped
APP_USER="azureuser"

echo "=== FormFlow (Azure) bootstrap started: $(date -u) ==="

if [ -f "$MARKER" ]; then
    echo "Bootstrap already completed on $(cat "$MARKER"). Exiting."
    exit 0
fi

retry() {
    local n=1 max=5 delay=10
    until "$@"; do
        if (( n >= max )); then
            echo "Command failed after $n attempts: $*" >&2
            return 1
        fi
        echo "Attempt $n/$max failed: $*. Retrying in ${delay}s..." >&2
        sleep "$delay"
        ((n++))
    done
}

# ---- Base packages ----
retry apt-get update -y
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git

# ---- Docker install (official Docker apt repo, not the outdated Ubuntu one) ----
install -m 0755 -d /etc/apt/keyrings

if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    retry curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
fi

if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    echo \
"deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null
fi

retry apt-get update -y
apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

systemctl enable docker
systemctl start docker

# Let the SSH user run docker without sudo (takes effect on next login)
usermod -aG docker "$APP_USER"

# ---- App directory: this is where the GitHub Actions deploy step will
# later drop docker-compose.yml and run `docker compose up -d` over SSH ----
mkdir -p /opt/capstone/app
chown -R "$APP_USER:$APP_USER" /opt/capstone

# ---- Verify installations (shows up in /var/log/user-data.log if you need to debug) ----
docker --version
docker compose version
git --version

date -u > "$MARKER"
echo "=== FormFlow (Azure) bootstrap finished: $(date -u) ==="
