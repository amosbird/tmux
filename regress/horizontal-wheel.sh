#!/bin/sh

PATH=/bin:/usr/bin
TERM=screen

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
[ -z "$TEST_TMUX" ] && TEST_TMUX=$(readlink -f "$SELF_DIR/../tmux")
TMUX="$TEST_TMUX -Ltest-horizontal-wheel"
TMUX2="$TEST_TMUX -Ltest-horizontal-wheel-inner"
$TMUX kill-server 2>/dev/null
$TMUX2 kill-server 2>/dev/null

TMP=$(mktemp)
trap '$TMUX kill-server 2>/dev/null; $TMUX2 kill-server 2>/dev/null; rm -f "$TMP"' 0 1 15

$TMUX2 -f/dev/null new -d || exit 1
$TMUX2 set -g mouse on
$TMUX2 bind -n WheelLeftPane run-shell "printf L >>'$TMP'"
$TMUX2 bind -n WheelRightPane run-shell "printf R >>'$TMP'"
$TMUX2 bind -n WheelUpPane run-shell "printf U >>'$TMP'"
$TMUX2 bind -n WheelDownPane run-shell "printf D >>'$TMP'"
$TMUX2 bind -n MouseDown6Pane run-shell "printf 6 >>'$TMP'"
$TMUX2 bind -n MouseDown7Pane run-shell "printf 7 >>'$TMP'"

$TMUX -f/dev/null new -d "$TMUX2 attach" || exit 1
sleep 0.1

# Kitty follows the SGR convention: 66 scrolls left and 67 scrolls right.
# Interleave horizontal and vertical events to cover diagonal touchpad gestures.
$TMUX send-keys -l "$(printf '\033[<66;1;1M\033[<64;1;1M\033[<67;1;1M\033[<65;1;1M')"
sleep 0.1

actual=$(cat "$TMP" 2>/dev/null)
if [ "$actual" != LURD ]; then
	echo "[FAIL] horizontal wheel classification (expected LURD, got '$actual')"
	exit 1
fi

# Every generated location-specific name must also round-trip through key parsing.
for direction in Left Right; do
	for location in Pane Status StatusLeft StatusRight StatusDefault Border; do
		key="Wheel${direction}${location}"
		if ! $TMUX2 bind -n "$key" display-message 2>/dev/null; then
			echo "[FAIL] cannot bind $key"
			exit 1
		fi
	done
done

[ -n "$VERBOSE" ] && echo "[PASS] SGR 66/67 -> WheelLeftPane/WheelRightPane"
exit 0
