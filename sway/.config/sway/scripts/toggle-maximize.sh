#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import json
import subprocess
import sys

MARK = "__sway_maximized"
BORDER_NORMAL = "border pixel 4"
BORDER_MAX = "border pixel 0"


def sway_get(msg: str):
    return json.loads(subprocess.check_output(["swaymsg", "-t", msg], text=True))


def sway_cmd(command: str) -> None:
    subprocess.run(
        ["swaymsg", "-t", "command", command],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def find_focused(node, workspace=None):
    if node.get("type") == "workspace":
        workspace = node
    if node.get("focused"):
        return node, workspace
    for child in node.get("nodes", []) + node.get("floating_nodes", []):
        found, ws = find_focused(child, workspace)
        if found is not None:
            return found, ws
    return None, workspace


tree = sway_get("get_tree")
focused, workspace = find_focused(tree)
if focused is None or workspace is None:
    sys.exit(0)

marks = focused.get("marks") or []
fullscreen = int(focused.get("fullscreen_mode") or 0)

if fullscreen:
    sway_cmd("fullscreen disable")

if MARK in marks:
    sway_cmd(f"unmark {MARK}")
    sway_cmd("floating disable")
    sway_cmd(BORDER_NORMAL)
    sys.exit(0)

rect = workspace.get("rect") or {}
x = int(rect.get("x") or 0)
y = int(rect.get("y") or 0)
w = int(rect.get("width") or 0)
h = int(rect.get("height") or 0)
if w <= 0 or h <= 0:
    sys.exit(0)

sway_cmd(f"mark --add {MARK}")
sway_cmd("floating enable")
sway_cmd(BORDER_MAX)
sway_cmd(f"resize set {w} px {h} px")
sway_cmd(f"move position {x} px {y} px")
PY
