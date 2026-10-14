#!/usr/bin/env bash
set -euo pipefail
TOOLS=${IRIS_DEMO_HOME:-/tmp/iris-editor-tools}
# The same 1280 × 720 layout at any scale. Cap keeps 60 fps only at 150% (1080p) on a CPU-only
# display; it managed 55 fps at 200% (1440p) and 11 fps at 300% (4K).
SCALE=${IRIS_DEMO_SCALE:-150}
case "$SCALE" in
  150) FACTOR=1.5 SIZE=1920x1080 ;;
  200) FACTOR=2 SIZE=2560x1440 ;;
  300) FACTOR=3 SIZE=3840x2160 ;;
  *) echo 'IRIS_DEMO_SCALE must be 150, 200 or 300' >&2; exit 1 ;;
esac
export DISPLAY=:94
export XDG_CURRENT_DESKTOP=GNOME
export FONTCONFIG_FILE="$TOOLS/fonts.conf"
export XCURSOR_THEME=Bibata-Modern-Ice
export XCURSOR_SIZE=32
export GDK_BACKEND=x11
export ELECTRON_OZONE_PLATFORM_HINT=x11

# This script runs under amp orb service. Its children share the supervised lifetime.
Xvfb "$DISPLAY" -screen 0 "${SIZE}x24" -nolisten tcp &
sleep 1
openbox &
exec "$TOOLS/VSCode-linux-x64/code" \
  --no-sandbox --disable-gpu --ozone-platform=x11 \
  --force-device-scale-factor="$FACTOR" \
  --remote-debugging-port=9223 \
  --user-data-dir "$TOOLS/profile" --extensions-dir "$TOOLS/extensions" \
  "$TOOLS/iris-website"
