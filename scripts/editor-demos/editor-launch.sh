#!/usr/bin/env bash
set -euo pipefail
TOOLS=${IRIS_DEMO_HOME:-/tmp/iris-editor-tools}
SCALE=${IRIS_DEMO_SCALE:-150}
case "$SCALE" in
  150) FACTOR=1.5 SIZE=1920x1080 ;;
  200) FACTOR=2 SIZE=2560x1440 ;;
  300) FACTOR=3 SIZE=3840x2160 ;;
  *) echo 'IRIS_DEMO_SCALE must be 150, 200 or 300' >&2; exit 1 ;;
esac
export XDG_CURRENT_DESKTOP=GNOME
export FONTCONFIG_FILE="$TOOLS/fonts.conf"
export GDK_BACKEND=x11
export ELECTRON_OZONE_PLATFORM_HINT=x11

source "$(dirname "$0")/display.sh"
exec "$TOOLS/VSCode-linux-x64/code" \
  --no-sandbox --disable-gpu --ozone-platform=x11 \
  --force-device-scale-factor="$FACTOR" \
  --remote-debugging-port=9223 \
  --user-data-dir "$TOOLS/profile" --extensions-dir "$TOOLS/extensions" \
  "$TOOLS/iris-website"
