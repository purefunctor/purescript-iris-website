#!/usr/bin/env bash
# Unpack Helium's portable Linux build for the playground trailer into $TOOLS/helium. Its .deb
# depends on Ubuntu's t64 library names, which Debian 12 lacks, so the take uses the tarball.
set -euo pipefail
TOOLS=${IRIS_DEMO_HOME:-/tmp/iris-editor-tools}
VERSION=0.19.4.1
ARCHIVE="helium-$VERSION-x86_64_linux.tar.xz"
mkdir -p "$TOOLS/downloads"
if [[ ! -f "$TOOLS/downloads/$ARCHIVE" ]]; then
  curl -fLsS --retry 2 "https://github.com/imputnet/helium-linux/releases/download/$VERSION/$ARCHIVE" \
    -o "$TOOLS/downloads/$ARCHIVE"
fi
rm -rf "$TOOLS/helium" && mkdir -p "$TOOLS/helium"
tar -xJf "$TOOLS/downloads/$ARCHIVE" -C "$TOOLS/helium" --strip-components=1
"$TOOLS/helium/helium" --version
