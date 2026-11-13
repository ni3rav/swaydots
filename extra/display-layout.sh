#!/usr/bin/env bash
# laptop: built-in screen only
# extend: every other connected screen to the right, at its own resolution
# clone:  a fullscreen copy of the built-in screen on each other screen
set -euo pipefail

mode=${1:-}
internal=${SWAYDOTS_INTERNAL_OUTPUT:-eDP-1}
state_dir=${XDG_CONFIG_HOME:-$HOME/.config}/nwg-displays
state_file=$state_dir/active_profile.json

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

outputs_json() {
  swaymsg -t get_outputs -r
}

externals() {
  outputs_json | jq -r --arg internal "$internal" '
    .[] | select(.name != $internal and (.name | startswith("__") | not)) | .name
  '
}

width_of() {
  outputs_json | jq -r --arg name "$1" '.[] | select(.name == $name) | .rect.width'
}

kill_mirrors() {
  if pgrep -x wl-mirror >/dev/null 2>&1; then
    pkill -x wl-mirror >/dev/null 2>&1 || true
    sleep 0.2
  fi
}

remember() {
  mkdir -p "$state_dir"
  if [[ -L "$state_file" ]]; then
    rm -f "$state_file"
  fi
  printf '{ "active_profile": "%s" }\n' "$mode" >"$state_file"
}

require_internal() {
  outputs_json | jq -e --arg name "$internal" '.[] | select(.name == $name)' >/dev/null \
    || fail "Built-in screen ${internal} is not connected"
}

require_external() {
  ((${#externals_list[@]})) || fail "No external monitor is connected"
}

place_right() {
  swaymsg "output \"${internal}\" enable pos 0 0" >/dev/null
  local x name w
  x=$(width_of "$internal")
  [[ "$x" =~ ^[0-9]+$ ]] || fail "Could not read the size of ${internal}"
  for name in "${externals_list[@]}"; do
    swaymsg "output \"${name}\" enable pos ${x} 0" >/dev/null
    w=$(width_of "$name")
    [[ "$w" =~ ^[0-9]+$ && "$w" != 0 ]] || fail "Could not enable ${name}"
    x=$((x + w))
  done
}

mapfile -t externals_list < <(externals)

case "$mode" in
  laptop)
    require_internal
    kill_mirrors
    swaymsg "output \"${internal}\" enable pos 0 0" >/dev/null
    for name in "${externals_list[@]}"; do
      swaymsg "output \"${name}\" disable" >/dev/null
    done
    ;;
  extend)
    require_internal
    require_external
    kill_mirrors
    place_right
    ;;
  clone)
    require_internal
    require_external
    command -v wl-mirror >/dev/null || fail "wl-mirror is not installed"
    kill_mirrors
    place_right
    for name in "${externals_list[@]}"; do
      wl-mirror --fullscreen-output "$name" --scaling fit "$internal" >/dev/null 2>&1 &
    done
    sleep 0.4
    pgrep -x wl-mirror >/dev/null || fail "Could not mirror onto the external monitor"
    ;;
  *)
    fail "Use laptop, extend, or clone"
    ;;
esac

remember
