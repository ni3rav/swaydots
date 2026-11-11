# Package reference

| Package | Home targets | Notes |
|---------|--------------|--------|
| `sway` | `~/.config/sway` | Modular `config.d/`; no Fedora `/etc/sway/config` (avoids `$mod+d` → rofi) |
| `ghostty` | (when added) | Terminal |
| `zsh` | `~/.zshrc`, `~/.zsh` | One `.zshrc` |
| `starship` | `~/.config/starship.toml` | COPR `atim/starship` |
| `fonts` | fonts + fontconfig | JetBrainsMono NF |
| `git` | `~/.gitconfig` | |
| `code` / `cursor` | User settings/keybindings | |
| `xdg` | mimeapps / portals hints | |

## Sway

- Includes `/etc/sway/config.d/*` (Fedora `sway-systemd`) then `config.d/*.conf`.
- `$mod+d` intentionally unbound.
- Apps: Ghostty (`$mod+Return`), Dolphin (`$mod+f`), Firefox (`$mod+b`).
- Noctalia IPC via `$ipc` (`noctalia msg`): launcher, clipboard, settings, control center (`$mod+o`), media, screenshots, lock.
- `$mod+period` → launcher (emoji slot; type in launcher for now).
- Maximize / fullscreen scripts under `scripts/` (stubs; refine live).

## Noctalia

- Autostart: `exec noctalia` in `10-autostart.conf`.
- Install: `sudo dnf install noctalia` (Fedora 44+).
- Greeter: Terra → `noctalia-greeter`; cutover only with `SWAYDOTS_ENABLE_GREETD=1`.

## Stow

```bash
cd ~/swaydots
stow -v --no-folding sway
```

Never stow `extra/`, `.skills/`, `.git`, `.cursor`. Restore: `bash extra/restore-fedora.sh`.
