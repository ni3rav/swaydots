#!/bin/bash
# Noctalia's sway template writes ~/.config/sway/noctalia, then runs this hook.
# Upstream only adds the include. Sway keeps the previous border colors until reload.
set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
config_file="$config_dir/sway/config"

if [[ "$config_dir" == "$HOME"/* ]]; then
  include_dir="~/${config_dir#"$HOME"/}"
else
  include_dir="$config_dir"
fi
include_line="include $include_dir/sway/noctalia"

mkdir -p "$(dirname "$config_file")"

if [ ! -f "$config_file" ]; then
  printf 'Warning: %s is missing; add the Noctalia theme include to your active Sway configuration manually:\ninclude "%s/sway/noctalia"\n' "$config_file" "$config_dir" >&2
  exit 1
fi

if ! grep -q '^include .*noctalia' "$config_file"; then
  printf '\n%s\n' "$include_line" >>"$config_file"
fi

sock="${SWAYSOCK:-}"
if [ -z "$sock" ] && [ -n "${XDG_RUNTIME_DIR:-}" ]; then
  sock="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name 'sway-ipc.*.sock' -print -quit 2>/dev/null || true)"
fi
if [ -n "$sock" ] && command -v swaymsg >/dev/null 2>&1; then
  SWAYSOCK="$sock" swaymsg reload >/dev/null 2>&1 || true
fi
