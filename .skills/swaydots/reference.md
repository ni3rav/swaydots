# Package reference

| Package | Home targets | Notes |
|---------|--------------|--------|
| `sway` | `~/.config/sway` | Modular `config.d/`; no Fedora `/etc/sway/config` |
| `xdg` | mimeapps, portals, terminals, autostart hides | Dolphin + Kate; Ghostty terminal; `wlr;gtk` portals |
| `zsh` | `~/.zshrc`, `~/.zsh` | Plugin submodules; one `.zshrc` |
| `starship` | `~/.config/starship.toml` | COPR `atim/starship` |
| `ghostty` | `~/.config/ghostty/config.ghostty` | TokyoNight + JetBrainsMono NF |
| `fonts` | fonts + fontconfig | JetBrainsMono NF, Plus Jakarta Sans, Noto Indic |
| `git` | `~/.gitconfig` | |
| `code` / `cursor` | User settings/keybindings | `cursor` also stows `~/.cursor/cli-config.json` (no account caches) |

## Sway

- Includes `/etc/sway/config.d/*` (Fedora `sway-systemd`) then `config.d/*.conf`.
- Workspaces 1–9 stay on `eDP-1`. `$mod+1`…`$mod+9` switch; `$mod+Shift+1`…`$mod+Shift+9` move the focused window.
- Caps→Esc via `input type:keyboard { xkb_options caps:escape }`. Num Lock stays on (`xkb_numlock enabled`).
- Apps: Ghostty (`$mod+Return`), Dolphin (`$mod+f`), Firefox (`$mod+b`).
- Noctalia IPC via `$ipc` (`noctalia msg`): launcher, clipboard, settings, control center (`$mod+o`), media, screenshots, lock.
- `$mod+period` → launcher `/emo` (emoji).

## Noctalia

- Autostart: `exec noctalia` in `10-autostart.conf`.
- Install: `sudo dnf install noctalia` (Fedora 44+).
- Greeter: Terra → `noctalia-greeter`; cutover with `SWAYDOTS_ENABLE_GREETD=1` then **reboot**. Fedora uses `user = "greetd"` in `/etc/greetd/config.toml`. `extra/50-noctalia-greeter.rules` lets the active user sync the palette without a password prompt.
- Power profiles: keep Fedora `tuned-ppd` (do not install `power-profiles-daemon`; they conflict).
- Desktop apps lean KDE/Qt: Dolphin, Kate, `plasma-systemsettings`, `plasma-systemmonitor`, `kclock`, `kamoso`.
- Notifications: Noctalia owns `org.freedesktop.Notifications`. Mask/remove `dunst`.
- Purge Sway-spin leftovers on restore: Thunar, rofi, foot, xfce4-panel.

## Stow

```bash
cd ~/swaydots
git submodule update --init --recursive
stow -v --no-folding sway xdg noctalia zsh starship ghostty fonts git code cursor fastfetch herdr opencode
```

Never stow `extra/`, `.skills/`, `.git`, `.cursor`. Restore: `bash extra/restore-fedora.sh`.
