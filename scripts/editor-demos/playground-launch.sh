#!/usr/bin/env bash
# The recording display for the playground trailer: Helium fullscreen at 100% on the 1920 × 1080
# display that display.sh starts, so the page lays out at 1920 × 1080 and Cap's zoom does the
# enlarging. The incognito window that opens the shared link is started by playground.mjs.
set -euo pipefail
TOOLS=${IRIS_DEMO_HOME:-/tmp/iris-editor-tools}
# Helium's portable Linux build, which playground-setup.sh unpacks.
BROWSER=${IRIS_DEMO_BROWSER:-$TOOLS/helium/helium}
source "$(dirname "$0")/display.sh"
# A fresh profile each launch, so the take starts without a saved project or layout.
rm -rf "$TOOLS/playground-profile"
exec "$BROWSER" \
  --user-data-dir="$TOOLS/playground-profile" \
  --remote-debugging-port=9224 \
  --force-device-scale-factor=1 \
  --window-position=0,0 --window-size=1920,1080 --start-fullscreen \
  --no-first-run --no-default-browser-check --disable-sync --disable-features=Translate --enable-features=OverlayScrollbar \
  --password-store=basic --hide-crash-restore-bubble \
  about:blank
