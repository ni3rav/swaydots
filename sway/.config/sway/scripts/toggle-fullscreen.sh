#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import json
import subprocess
import sys

MARK = "__sway_maximized"
BORDER_NORMAL = "border pixel 4"


def sway_get(msg: str):
    return json.loads(subprocess.check_output(["swaymsg", "-t", msg], text=True))


def sway_cmd(command: str) -> None:
    subprocess.run(
        ["swaymsg", "-t", "command", command],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def find_focused(node):
    if node.get("focused"):
        return node
    for child in node.get("nodes", []) + node.get("floating_nodes", []):
        found = find_focused(child)
        if found is not None:
            return found
    return None


tree = sway_get("get_tree")
focused = find_focused(tree)
if focused is None:
    sys.exit(0)

con_id = int(focused["id"])
marks = focused.get("marks") or []
fullscreen = int(focused.get("fullscreen_mode") or 0)
target = f"[con_id={con_id}]"

if MARK in marks and not fullscreen:
    sway_cmd(f"{target} unmark {MARK}")
    sway_cmd(f"{target} floating disable")
    sway_cmd(f"{target} {BORDER_NORMAL}")

sway_cmd(f"{target} fullscreen toggle")
PY
