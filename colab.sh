#!/bin/bash
set -e

echo "=== docker-android / Colab mode ==="

# Colab does not grant the network administration permissions that
# Docker's default bridge/NAT setup requires. Disable Docker's iptables
# management and use host networking for the container.
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
fi

DOCKERD_ARGS=(
  --iptables=false
  --bridge=none
)

if ! docker info >/dev/null 2>&1; then
  nohup dockerd "${DOCKERD_ARGS[@]}" >/tmp/dockerd.log 2>&1 &
  for i in {1..45}; do
    if docker info >/dev/null 2>&1; then
      break
    fi
    sleep 2
  done
fi

docker info >/dev/null 2>&1 || {
  echo "Docker daemon is unavailable in this Colab runtime."
  echo
  echo "Last Docker daemon log:"
  tail -n 80 /tmp/dockerd.log 2>/dev/null || true
  exit 1
}

echo "Docker daemon is ready."

docker build -t android-emulator .
docker build -f Dockerfile.colab -t android-colab .

docker rm -f android-colab >/dev/null 2>&1 || true

# Host networking avoids Docker bridge/NAT creation, which Colab blocks.
# The Colab image exposes noVNC on port 6080 and ADB on 5555.
docker run -d   --name android-colab   --network host   android-colab

sleep 8
docker logs android-colab --tail 40 || true

if [ ! -x /content/cloudflared ]; then
  wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /content/cloudflared
  chmod +x /content/cloudflared
fi

echo
echo "Open the HTTPS URL below, then append /vnc.html"
echo

exec /content/cloudflared tunnel --url http://127.0.0.1:6080
