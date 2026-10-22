# Sourced by the launch scripts: the recording display, :94 at $SIZE (1920x1080 by default), with the
# cursor theme that Cap records, and Openbox without window decorations. Helium leaves its frame to
# the window manager, and VS Code records under its own F11 fullscreen, so neither needs one.
# It runs under amp orb service, and its children share the supervised lifetime.
TOOLS=${IRIS_DEMO_HOME:-/tmp/iris-editor-tools}
export DISPLAY=:94
export XCURSOR_THEME=Bibata-Modern-Ice
export XCURSOR_SIZE=32
Xvfb "$DISPLAY" -screen 0 "${SIZE:-1920x1080}x24" -nolisten tcp &
sleep 1
mkdir -p "$TOOLS/openbox"
cat > "$TOOLS/openbox/rc.xml" <<'XML'
<?xml version="1.0"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <applications><application class="*"><decor>no</decor></application></applications>
</openbox_config>
XML
openbox --config-file "$TOOLS/openbox/rc.xml" &
