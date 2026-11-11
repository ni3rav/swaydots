# swaydots

Fedora + Sway (WM) + Noctalia (shell), managed with GNU Stow (`stow -v --no-folding …` from this repo).

Home paths are symlinks into this tree — edit here, then commit. Don’t replace a symlink with a regular file.

`extra/` and `.skills/` are not stowed.

| Package | Maps to |
|---------|---------|
| `sway` | `~/.config/sway` — keybinds/WM only; Noctalia for launcher/OSD/bar/lock |
| `xdg` | mimeapps, portals, `environment.d` + `qt6ct` for Qt theming |
| `noctalia` | bar + builtin and community theme templates |
| `zsh` | `~/.zshrc`, `~/.zsh` plugins (submodules) |
| `starship` | `~/.config/starship.toml` |
| `ghostty` | `~/.config/ghostty/config.ghostty` |
| `fonts` | fonts + fontconfig |
| `git` | `~/.gitconfig` |
| `code` | VS Code User settings/keybindings |
| `cursor` | Cursor User settings/keybindings |

Thin thread: Sway moves windows; every GUI verb is `noctalia msg …`. Qt apps need `qt6ct` + `QT_QPA_PLATFORMTHEME=qt6ct` (stowed; re-login after first stow).

Ghostty uses `theme = noctalia` and Sway includes `~/.config/sway/noctalia`. zsh sources the generated fzf colors and points Glow at its generated style. Noctalia rewrites those theme files when the palette changes, so they stay generated and are not stowed. The Starship template also injects a palette block into `starship.toml`.

```bash
git clone --recurse-submodules <repo-url> ~/swaydots
cd ~/swaydots
git submodule update --init --recursive
stow -v --no-folding sway xdg noctalia zsh starship ghostty fonts git code cursor
fc-cache -fv
```

Fresh machine: `bash extra/restore-fedora.sh`
