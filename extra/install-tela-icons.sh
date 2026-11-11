#!/usr/bin/env bash
# Install Tela icons into ~/.local/share/icons (no root needed).
set -euo pipefail
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
if [[ -d "$DEST/Tela-dark" ]]; then
  printf 'Tela-dark already present at %s\n' "$DEST/Tela-dark"
  exit 0
fi
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
git clone --depth 1 https://github.com/vinceliuice/Tela-icon-theme.git "$tmpdir/Tela"
"$tmpdir/Tela/install.sh" -d "$DEST" standard
"$tmpdir/Tela/install.sh" -d "$DEST" black
printf 'Installed Tela variants under %s\n' "$DEST"
