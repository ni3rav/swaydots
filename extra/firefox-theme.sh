#!/usr/bin/env bash
# Install the Noctalia Firefox host and force-install Pywalfox.
# Asks for sudo once. Restart Firefox after it finishes.
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
policy_src="$root/extra/firefox-policies.json"
policy_dir="/etc/firefox/policies"

command -v noctalia >/dev/null 2>&1 || {
  echo "noctalia is not installed" >&2
  exit 1
}
[[ -f "$policy_src" ]] || {
  echo "missing $policy_src" >&2
  exit 1
}

noctalia firefox-theme install

sudo mkdir -p "$policy_dir"
sudo cp "$policy_src" "$policy_dir/policies.json"
sudo chmod 644 "$policy_dir/policies.json"

echo "Pywalfox host is installed."
echo "Restart Firefox once. The extension installs on that start, then the palette follows Noctalia."
