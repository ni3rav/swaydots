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
| `starship` | `~/.config/starship.toml` (Noctalia palette block included) |
| `ghostty` | `~/.config/ghostty/config.ghostty` (`theme = noctalia`) |
| `fastfetch` | `~/.config/fastfetch/config.jsonc` |
| `herdr` | `~/.config/herdr/config.toml` (`[theme.custom]`) |
| `opencode` | `~/.config/opencode/opencode.json` (theme `matugen`) |
| `fonts` | fonts + fontconfig |
| `git` | `~/.gitconfig` |
| `code` | VS Code User settings/keybindings |
| `cursor` | Cursor editor settings, plus `~/.cursor/cli-config.json` for the agent CLI |

Thin thread: Sway moves windows; every GUI verb is `noctalia msg …`. Qt apps need `qt6ct` + `QT_QPA_PLATFORMTHEME=qt6ct` (stowed; re-login after first stow).

Enabled templates:

| Template | What is stowed |
| --- | --- |
| gtk3, gtk4, qt, kcolorscheme | GTK settings and qt6ct. The color scheme files are generated. |
| ghostty, sway | `theme = noctalia`, and Sway includes `~/.config/sway/noctalia`. The theme files are generated. |
| papirus-icons | Icon theme name `Papirus-Dark`. The recolored icon copies are not stowed. |
| bat, fzf, glow | zsh sources the fzf snippet and sets `GLOW_STYLE`. bat's `--theme=noctalia` config is generated. |
| starship, fastfetch, herdr | Prompt, fastfetch, and Herdr configs are stowed and include the current palette. Noctalia rewrites those color blocks. |
| opencode | `theme = matugen`. The theme JSON is generated. |
| lazydocker, antigravity | Hooks write their own configs. Those files are not stowed. |
| libreoffice, brave, brave-origin, chromium-based | Enabled. The hooks need the app installed (and a browser profile, or Chromium's one-time policy setup) before they can write. |
| pywalfox | Firefox follows the palette. Noctalia is the native host. `bash extra/firefox-theme.sh` installs the host and the extension policy; restart Firefox after. |

`extra/restore-fedora.sh` installs fastfetch, Papirus, and the Cursor agent CLI (`agent` on `~/.local/bin`), installs the Pywalfox host, stows the packages above, then runs `noctalia msg templates-apply`. Desktop apps are Dolphin, Kate, Ark, GNOME Clocks, Snapshot, and KDE Connect. Super+E opens Noctalia settings. Super+1 through Super+9 switch workspaces, and Super+Shift+1 through Super+Shift+9 move the focused window. The lock screen fades in over 200 ms. Bar edits and the login-screen palette apply on their own. `bash extra/sync-noctalia-bar.sh` copies the live bar into the stowed config when the repo should match.

```bash
git clone --recurse-submodules <repo-url> ~/swaydots
cd ~/swaydots
git submodule update --init --recursive
stow -v --no-folding sway xdg noctalia zsh starship ghostty fonts git code cursor fastfetch herdr opencode
fc-cache -fv
```

Fresh machine: `bash extra/restore-fedora.sh`
