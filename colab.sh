#!/bin/bash
set -e

echo "=== docker-android / Colab mode ==="

if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
fi

if ! docker info >/dev/null 2>&1; then
  nohup dockerd >/tmp/dockerd.log 2>&1 &
  for i in {1..30}; do
    docker info >/dev/null 2>&1 && break
    sleep 2
  done
fi

docker info >/dev/null 2>&1 || {
  echo "Docker daemon is unavailable in this Colab runtime."
  cat /tmp/dockerd.log 2>/dev/null || true
  exit 1
}

docker build -t android-emulator .
docker build -f Dockerfile.colab -t android-colab .

docker rm -f android-colab >/dev/null 2>&1 || true

docker run -d --name android-colab -p 5555:5555 -p 6080:6080 android-colab

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
