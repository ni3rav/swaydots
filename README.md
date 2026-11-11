# swaydots

Fedora + Sway (WM) + Noctalia (shell), managed with GNU Stow (`stow -v --no-folding …` from this repo).

Home paths are symlinks into this tree — edit here, then commit. Don’t replace a symlink with a regular file.

`extra/` and `.skills/` are not stowed.

| Package | Maps to |
|---------|---------|
| `sway` | `~/.config/sway` — keybinds/WM only; Noctalia for launcher/OSD/bar/lock |
| `xdg` | mimeapps (Dolphin/Kate), portals (`wlr;gtk`), Ghostty terminal list |

Thin thread: Sway moves windows; every GUI verb is `noctalia msg …`.

```bash
git clone <repo-url> ~/swaydots
cd ~/swaydots
stow -v --no-folding sway xdg
```


Fresh machine: `bash extra/restore-fedora.sh`
