#!/bin/bash
set -e

echo "=== docker-android / Colab mode ==="

if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
fi

DOCKERD_ARGS=(--iptables=false --bridge=none)

if ! docker info >/dev/null 2>&1; then
  nohup dockerd "${DOCKERD_ARGS[@]}" >/tmp/dockerd.log 2>&1 &
  for i in {1..45}; do
    docker info >/dev/null 2>&1 && break
    sleep 2
  done
fi

docker info >/dev/null 2>&1 || {
  echo "Docker daemon is unavailable in this Colab runtime."
  tail -n 100 /tmp/dockerd.log 2>/dev/null || true
  exit 1
}

echo "Docker daemon is ready."

# Build only the Colab image. The original Dockerfile is intentionally
# untouched and is not used here, so a Colab-specific base/dependency
# issue cannot break the normal project image.
docker build --progress=plain -f Dockerfile.colab -t android-colab .

docker rm -f android-colab >/dev/null 2>&1 || true

docker run -d \
  --name android-colab \
  --network host \
  android-colab

sleep 10
echo
echo "=== Android container logs ==="
docker logs android-colab --tail 80 || true

if [ ! -x /content/cloudflared ]; then
  wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /content/cloudflared
  chmod +x /content/cloudflared
fi

echo
echo "=== noVNC HTTPS URL ==="
echo "Open the URL below and append /vnc.html"
echo

exec /content/cloudflared tunnel --url http://127.0.0.1:6080
