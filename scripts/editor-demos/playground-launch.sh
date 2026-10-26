#!/usr/bin/env bash
set -euo pipefail
TOOLS=${IRIS_DEMO_HOME:-/tmp/iris-editor-tools}
BROWSER=${IRIS_DEMO_BROWSER:-$TOOLS/helium/helium}
source "$(dirname "$0")/display.sh"
rm -rf "$TOOLS/playground-profile"
exec "$BROWSER" \
  --user-data-dir="$TOOLS/playground-profile" \
  --remote-debugging-port=9224 \
  --force-device-scale-factor=1 \
  --window-position=0,0 --window-size=1920,1080 --start-fullscreen \
  --no-first-run --no-default-browser-check --disable-sync --disable-features=Translate --enable-features=OverlayScrollbar \
  --password-store=basic --hide-crash-restore-bubble \
  about:blank
