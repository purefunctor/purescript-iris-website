# Sourced by the launch scripts: the recording display, :94 at $SIZE (1920x1080 by default), with the
# cursor theme that Cap records, and Openbox.
# It runs under amp orb service, and its children share the supervised lifetime.
export DISPLAY=:94
export XCURSOR_THEME=Bibata-Modern-Ice
export XCURSOR_SIZE=32
Xvfb "$DISPLAY" -screen 0 "${SIZE:-1920x1080}x24" -nolisten tcp &
sleep 1
openbox &
