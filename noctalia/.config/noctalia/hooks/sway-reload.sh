#!/usr/bin/env bash
# Noctalia colors_changed hook. Reloads Sway so window borders follow
# the palette just written to ~/.config/sway/noctalia.
set -euo pipefail

sock="${SWAYSOCK:-}"
if [[ -z "$sock" && -n "${XDG_RUNTIME_DIR:-}" ]]; then
  sock="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name 'sway-ipc.*.sock' -print -quit 2>/dev/null || true)"
fi
if [[ -n "$sock" ]] && command -v swaymsg >/dev/null 2>&1; then
  SWAYSOCK="$sock" swaymsg reload >/dev/null 2>&1 || true
fi
