#!/usr/bin/env bash
set -euo pipefail
TOOLS=${IRIS_DEMO_HOME:-/tmp/iris-editor-tools}
SCALE=${IRIS_DEMO_SCALE:-150}
case "$SCALE" in 150) FACTOR=1.5 ;; 200) FACTOR=2 ;; *) echo 'IRIS_DEMO_SCALE must be 150 or 200' >&2; exit 1 ;; esac
export DISPLAY=:94
export XDG_CURRENT_DESKTOP=GNOME
export FONTCONFIG_FILE="$TOOLS/fonts.conf"
export XCURSOR_THEME=Bibata-Modern-Ice
export XCURSOR_SIZE=32
export GDK_BACKEND=x11
export ELECTRON_OZONE_PLATFORM_HINT=x11

# This script runs under amp orb service. Its children share the supervised lifetime.
Xvfb "$DISPLAY" -screen 0 1920x1080x24 -nolisten tcp &
sleep 1
openbox &
exec "$TOOLS/VSCode-linux-x64/code" \
  --no-sandbox --disable-gpu --ozone-platform=x11 \
  --force-device-scale-factor="$FACTOR" \
  --remote-debugging-port=9223 \
  --user-data-dir "$TOOLS/profile" --extensions-dir "$TOOLS/extensions" \
  "$TOOLS/iris-website"
