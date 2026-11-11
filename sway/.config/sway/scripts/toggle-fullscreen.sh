#!/usr/bin/env bash
# True fullscreen (hide chrome). Mirror of i3 toggle-fullscreen chord.
set -euo pipefail
swaymsg fullscreen toggle
