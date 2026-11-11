#!/usr/bin/env bash
# Maximize: fullscreen with bar still reserved when possible.
# Refine once Noctalia bar + sway fullscreen quirks are verified live.
set -euo pipefail
swaymsg fullscreen toggle
