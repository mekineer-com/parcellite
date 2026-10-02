#!/bin/sh
# Native hover acceptance on an isolated display; no real clipboard/history.
set -eu
binary=$(realpath "${1:-$(dirname "$0")/../src/parcellite}")
tmp=$(mktemp -d /tmp/parcellite-tooltip.XXXXXX)
app=''; xvfb=''
cleanup() {
    test -z "$app" || kill "$app" 2>/dev/null || true
    test -z "$xvfb" || kill "$xvfb" 2>/dev/null || true
}
trap cleanup EXIT HUP INT TERM
mkdir -p "$tmp/home" "$tmp/config/parcellite" "$tmp/data"
export HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/config" XDG_DATA_HOME="$tmp/data"
cat > "$tmp/config/parcellite/parcelliterc" <<'EOF'
[rc]
use_copy=true
use_primary=false
save_history=false
automatic_paste=false
item_length=50
single_line=true
history_pos=true
history_x=20
history_y=40
history_key=<Alt>V
no_icon=true
EOF
python3 - "$tmp/payload" <<'PY'
from pathlib import Path
import sys
Path(sys.argv[1]).write_text('FULL_CLIP_START <b>literal markup</b> & "quotes"\n'
                           'Second line with a preserved newline.\n'
                           + 'A roomy preview can display the text missing from the menu. ' * 6
                           + '\nFULL_CLIP_END\n\n  ', encoding='utf-8')
PY
Xvfb -displayfd 3 -screen 0 1024x768x24 -nolisten tcp 3> "$tmp/display" > "$tmp/xvfb.log" 2>&1 &
xvfb=$!
for n in $(seq 1 50); do test ! -s "$tmp/display" || break; sleep 0.1; done
test -s "$tmp/display"
export DISPLAY=":$(cat "$tmp/display")"
xclip -selection clipboard -i "$tmp/payload"
"$binary" > "$tmp/app.log" 2>&1 &
app=$!
sleep 1
xdotool key alt+v
xdotool mousemove 80 54
sleep 1.5
tip=''
menu=''
for window in $(xdotool search --onlyvisible --pid "$app"); do
    if xprop -id "$window" _NET_WM_WINDOW_TYPE | grep -q '_NET_WM_WINDOW_TYPE_TOOLTIP'; then
        tip=$window
    elif xprop -id "$window" _NET_WM_WINDOW_TYPE | grep -q '_NET_WM_WINDOW_TYPE_POPUP_MENU'; then
        menu=$window
    fi
done
test -n "$tip" || { echo "No visible tooltip; evidence: $tmp"; exit 1; }
test -n "$menu"
right=$(xdotool getwindowgeometry --shell "$menu" | awk -F= '/^X=/{x=$2} /^WIDTH=/{print x+$2-5}')
xdotool getwindowgeometry --shell "$tip" > "$tmp/geometry-before"
for point in '83 54' '300 60' "$right 64" '80 54'; do
    xdotool mousemove $point
    sleep 0.8
    xwininfo -id "$tip" | grep -q 'Map State: IsViewable'
    xdotool getwindowgeometry --shell "$tip" > "$tmp/geometry-after"
    cmp "$tmp/geometry-before" "$tmp/geometry-after"
done
xclip -selection clipboard -o > "$tmp/after-hover"
cmp "$tmp/payload" "$tmp/after-hover"
python3 - "$tmp/hover.png" <<'PY'
import sys
from PyQt6.QtWidgets import QApplication
app = QApplication([])
assert app.primaryScreen().grabWindow(0).save(sys.argv[1])
PY
for cycle in 1 2 3; do
    xdotool key Escape
    sleep 0.2
    xdotool key alt+v
    xdotool mousemove 80 54
    sleep 1
    kill -0 "$app"
done
xdotool key Escape
sleep 0.2
if grep -Eq 'CRITICAL|invalid.*(pointer|object)' "$tmp/app.log"; then
    cat "$tmp/app.log"
    exit 1
fi
xclip -selection clipboard -o > "$tmp/after-close"
cmp "$tmp/payload" "$tmp/after-close"
echo "PASS: native tooltip stays still within its row; clipboard unchanged. Evidence: $tmp"
