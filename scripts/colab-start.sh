#!/bin/bash
set -e

export DISPLAY=:0

Xvfb :0 -screen 0 1280x720x24 -ac >/tmp/xvfb.log 2>&1 &
sleep 2
fluxbox >/tmp/fluxbox.log 2>&1 &
sleep 2

x11vnc -display :0 -forever -shared -rfbport 5900 -nopw -listen 0.0.0.0 >/tmp/x11vnc.log 2>&1 &
websockify --web=/usr/share/novnc 0.0.0.0:6080 localhost:5900 >/tmp/novnc.log 2>&1 &

adb -a -P 5037 server nodaemon >/tmp/adb.log 2>&1 &

echo no | avdmanager create avd --force --name android --abi "$ABI" --package "$PACKAGE_PATH" --device "$DEVICE_ID"

emulator -avd android -gpu swiftshader_indirect -memory "${MEMORY:-4096}" -cores "${CORES:-2}" -no-boot-anim -no-snapshot -no-audio -no-accel -ports 5554,5555 >/tmp/emulator.log 2>&1 &

echo "noVNC listening on port 6080"
tail -f /tmp/emulator.log
