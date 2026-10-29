#!/usr/bin/env bash
set -euo pipefail
TOOLS=${IRIS_DEMO_HOME:-/tmp/iris-editor-tools}
ROOT=${IRIS_CAP_CHROOT:-/srv/cap-noble}
DEB=https://cdn.crabnebula.app/asset/01M2JEFM7ZZKVZT9YPEKWWFPD7
SHA256=d8a270ebefbb3031baf002bd922b70a88c51985ab545324672f374b9e99005a4
mkdir -p "$TOOLS"

if [[ ! -f "$TOOLS/cap-0.6.0.deb" ]]; then
  curl -fLsS --retry 2 "$DEB" -o "$TOOLS/cap-0.6.0.deb"
fi
echo "$SHA256  $TOOLS/cap-0.6.0.deb" | sha256sum -c -

JAMMY_SCRIPT_FOR_NOBLE=/usr/share/debootstrap/scripts/jammy
if [[ ! -x "$ROOT/usr/bin/apt-get" ]]; then
  sudo apt-get install -y -qq debootstrap
  sudo debootstrap --variant=minbase --components=main,universe noble "$ROOT" \
    http://archive.ubuntu.com/ubuntu "$JAMMY_SCRIPT_FOR_NOBLE"
fi

cat > "$TOOLS/cap-cli" <<EOF
#!/usr/bin/env bash
set -euo pipefail
for d in proc sys dev dev/pts tmp; do
  mountpoint -q "$ROOT/\$d" || sudo mount --rbind "/\$d" "$ROOT/\$d"
done
mkdir -p /tmp/cap-home/run && chmod 700 /tmp/cap-home/run
exec sudo chroot --userspec="\$(id -u):\$(id -g)" "$ROOT" env -i HOME=/tmp/cap-home \\
  XDG_RUNTIME_DIR=/tmp/cap-home/run DISPLAY=:94 XDG_SESSION_TYPE=x11 PATH=/usr/bin:/bin cap-cli "\$@"
EOF
chmod +x "$TOOLS/cap-cli"

if ! "$TOOLS/cap-cli" --version >/dev/null 2>&1; then
  sudo cp /etc/resolv.conf "$ROOT/etc/resolv.conf"
  sudo install -D -m 644 "$TOOLS/cap-0.6.0.deb" "$ROOT/opt/cap-0.6.0.deb"
  sudo chroot "$ROOT" env DEBIAN_FRONTEND=noninteractive apt-get update -qq
  sudo chroot "$ROOT" env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    /opt/cap-0.6.0.deb mesa-vulkan-drivers libgl1-mesa-dri ca-certificates
fi
"$TOOLS/cap-cli" --version
