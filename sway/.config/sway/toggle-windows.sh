#!/usr/bin/env bash
# Hide and restore windows. Super+D toggles every window; Super+Shift+D toggles the focused one.
set -euo pipefail
exec python3 - "$@" <<'PY'
import json
import os
import subprocess
import sys

runtime = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
state_all = os.path.join(runtime, "swaydots-hidden-windows")
state_focused = os.path.join(runtime, "swaydots-hidden-focused")
skip_apps = {"noctalia", "dev.noctalia.Noctalia"}


def sway(*args):
    subprocess.run(["swaymsg", "--", *args], check=False, stdout=subprocess.DEVNULL)


def tree():
    return json.loads(subprocess.check_output(["swaymsg", "-t", "get_tree"]))


def walk(node, workspace, found):
    if node.get("type") == "workspace":
        workspace = node.get("name")
    children = node.get("nodes", []) + node.get("floating_nodes", [])
    if (
        workspace
        and workspace != "__i3_scratch"
        and node.get("pid")
        and node.get("type") in ("con", "floating_con")
        and (node.get("app_id") or "") not in skip_apps
        and not any(child.get("pid") for child in children)
    ):
        found.append(
            {
                "id": node["id"],
                "workspace": workspace,
                "focused": bool(node.get("focused")),
            }
        )
    for child in children:
        walk(child, workspace, found)


def windows():
    found = []
    walk(tree(), None, found)
    return found


def read_state(path):
    if not os.path.isfile(path):
        return []
    rows = []
    with open(path) as handle:
        for line in handle:
            con_id, workspace = line.split(maxsplit=1)
            rows.append((int(con_id), workspace.strip()))
    return rows


def write_state(path, rows):
    if not rows:
        try:
            os.remove(path)
        except FileNotFoundError:
            pass
        return
    with open(path, "w") as handle:
        for con_id, workspace in rows:
            handle.write(f"{con_id} {workspace}\n")


def scratchpad_ids():
    hidden = set()

    def mark(node, workspace):
        if node.get("type") == "workspace":
            workspace = node.get("name")
        if workspace == "__i3_scratch" and node.get("id") is not None:
            hidden.add(node["id"])
        for child in node.get("nodes", []) + node.get("floating_nodes", []):
            mark(child, workspace)

    mark(tree(), None)
    return hidden


def restore(path):
    rows = read_state(path)
    try:
        os.remove(path)
    except FileNotFoundError:
        pass
    hidden = scratchpad_ids()
    restored = []
    for con_id, workspace in rows:
        if con_id not in hidden:
            continue
        sway(f"[con_id={con_id}]", "move", "container", "to", "workspace", workspace)
        restored.append(con_id)
    if restored:
        sway(f"[con_id={restored[-1]}]", "focus")


def hide(rows, path):
    moved = []
    for con_id, workspace in rows:
        sway(f"[con_id={con_id}]", "move", "container", "to", "scratchpad")
        moved.append((con_id, workspace))
    write_state(path, moved)


def toggle_all():
    if os.path.isfile(state_all):
        restore(state_all)
        return
    hide([(window["id"], window["workspace"]) for window in windows()], state_all)


def toggle_focused():
    if os.path.isfile(state_focused):
        restore(state_focused)
        return
    focused = next((window for window in windows() if window["focused"]), None)
    if focused is None:
        return
    hide([(focused["id"], focused["workspace"])], state_focused)


command = sys.argv[1] if len(sys.argv) > 1 else ""
if command == "--focused":
    toggle_focused()
elif command == "":
    toggle_all()
else:
    print("Usage: toggle-windows.sh [--focused]", file=sys.stderr)
    sys.exit(2)
PY
