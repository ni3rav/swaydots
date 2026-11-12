#!/usr/bin/env bash
# Copy the live Noctalia bar into the stowed config. Run it when you want
# that file to catch up. Noctalia itself applies bar edits immediately.
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
exec python3 - "$root" <<'PY'
import subprocess
import sys
import tomllib
from pathlib import Path

root = Path(sys.argv[1])
target = root / "noctalia/.config/noctalia/10-bar.toml"
settings_path = Path.home() / ".local/state/noctalia/settings.toml"
if not settings_path.is_file() or not target.is_file():
    sys.exit(0)

settings = tomllib.loads(settings_path.read_text())
bar = subprocess.check_output(["noctalia", "msg", "config-get", "bar.default"], text=True)
bar_data = tomllib.loads(bar)
current = target.read_text()
marker = "\n[shell.panel]"
tail = current[current.index(marker):] if marker in current else "\n"

theme = settings.get("theme", {})
theme_keys = ("mode", "source", "builtin", "wallpaper_scheme")


def lit(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, float):
        value = round(value, 4)
        text = f"{value:.4f}".rstrip("0").rstrip(".")
        return text if "." in text else f"{text}.0"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, str):
        return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'
    if isinstance(value, list):
        return "[ " + ", ".join(lit(item) for item in value) + " ]"
    raise TypeError(type(value))


def table(name, data, skip=()):
    lines = [f"[{name}]"]
    for key, value in data.items():
        if key in skip or isinstance(value, dict):
            continue
        if isinstance(value, list) and any(isinstance(item, (dict, list)) for item in value):
            continue
        lines.append(f"{key} = {lit(value)}")
    return "\n".join(lines)


placed = []
for key in ("start", "center", "end"):
    for item in bar_data.get(key, []):
        if item.startswith("group:"):
            continue
        placed.append(item)
for group in bar_data.get("capsule_group", []):
    for item in group.get("members", []):
        if item not in placed:
            placed.append(item)

parts = [
    "# Bar follows the wallpaper palette. Compact alt-tab.",
    "",
    table("theme", {key: theme[key] for key in theme_keys if key in theme}),
    "",
    '[bar]\norder = ["default"]',
    "",
    table("bar.default", bar_data, skip=("capsule_group", "dead_zone")),
]
for group in bar_data.get("capsule_group", []):
    parts.append("")
    parts.append(table("bar.default.capsule_group", group).replace(
        "[bar.default.capsule_group]", "[[bar.default.capsule_group]]", 1
    ))

for name in placed:
    result = subprocess.run(
        ["noctalia", "msg", "config-get", f"widget.{name}"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        continue
    widget = tomllib.loads(result.stdout)
    actions = widget.get("actions")
    parts.append("")
    parts.append(table(f"widget.{name}", widget, skip=("actions",)))
    if isinstance(actions, dict):
        parts.append("")
        parts.append(table(f"widget.{name}.actions", actions))

text = "\n".join(parts).rstrip() + "\n\n" + tail.lstrip("\n")
if not text.endswith("\n"):
    text += "\n"
if target.read_text() != text:
    target.write_text(text)
PY
