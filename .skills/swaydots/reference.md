# Package reference

| Package | Home targets | Notes |
|---------|--------------|--------|
| `sway` | `~/.config/sway` | Modular `config.d/`; no Fedora `/etc/sway/config` |
| `xdg` | mimeapps, portals, terminals, autostart hides | Thunar + Kate; Ghostty terminal; Brave Origin default browser; `wlr;gtk` portals |
| `brave-origin` | `~/.config/BraveSoftware/Brave-Origin/swaydots/extensions.json` | Installed extensions and the Proton Pass shortcut. Restore force-installs that list. There is no Noctalia theme template. When Brave Origin is closed, restore sets Appearance to Use GTK (`extensions.theme.system_theme = 1`), so it follows the Noctalia GTK palette. |
| `zsh` | `~/.zshrc`, `~/.zsh` | Plugin submodules; one `.zshrc` |
| `starship` | `~/.config/starship.toml` | COPR `atim/starship` |
| `ghostty` | `~/.config/ghostty/config.ghostty` | TokyoNight + JetBrainsMono NF |
| `fonts` | fonts + fontconfig | JetBrainsMono NF, Plus Jakarta Sans, Noto Indic |
| `git` | `~/.gitconfig` | |
| `codium` / `cursor` | User settings/keybindings | Default profile is the dev extension list; `jupyter` is the only other profile. Both use the same settings: Dark Modern, hidden activity bar, command center off. New extensions: **Sync Settings: Upload** in that profile (`codium/sync`). `~/.cursor/cli-config.json` is seeded once from `extra/cursor-cli-config.json` by `step_cursor_cli`, not stowed, because the CLI rewrites it with account state |

## Sway

- Includes `/etc/sway/config.d/*` (Fedora `sway-systemd`) then `config.d/*.conf`.
- Workspaces 1–6 stay on `eDP-1`. `$mod+1`…`$mod+6` switch; `$mod+Shift+1`…`$mod+Shift+6` move the focused window.
- Caps→Esc via `input type:keyboard { xkb_options caps:escape }`. Num Lock stays on (`xkb_numlock enabled`).
- Apps: Ghostty (`$mod+Return`), Thunar (`$mod+f`), Brave Origin (`$mod+b`). Firefox stays installed.
- Noctalia IPC via `$ipc` (`noctalia msg`): launcher, clipboard, settings, control center (`$mod+o`), media, screenshots, lock.
- `$mod+period` → launcher `/emo` (emoji).

## Noctalia

- Autostart: `exec noctalia` in `10-autostart.conf`.
- Install: `sudo dnf install noctalia` (Fedora 44+).
- Greeter: Terra → `noctalia-greeter`; cutover with `SWAYDOTS_ENABLE_GREETD=1` then **reboot**. Fedora uses `user = "greetd"` in `/etc/greetd/config.toml`. `gnome-keyring-pam` is installed so greetd unlocks the `login` keyring with the login password. `shell.greeter_sync.auto_sync` is on, and `extra/50-noctalia-greeter.rules` lets the active user sync the palette.
- Everything is opaque with no blur: bar and panels (`10-bar.toml`, `transparency_mode = "solid"`), dock, OSD, toasts, backdrop and lock screen (`15-solid.toml`), and Ghostty (default opacity).
- Bar edits apply immediately. `~/.config/noctalia/50-hooks.toml` runs `hooks/sync-bar.sh` on `started` and `colors_changed`, which copies the live bar into `10-bar.toml`. Run that script to copy the bar before the next start or palette change.
- Window borders come from `~/.config/sway/noctalia`. The `colors_changed` hook runs `hooks/sway-reload.sh` (`swaymsg reload`) after the palette is written.
- The bar is at the bottom (`10-bar.toml`, 28px, spacing 20). Left: workspaces. Right, in order: tray, notifications, then CPU, RAM, CPU temperature, download and upload as an icon plus a value, then battery percentage, brightness, the media glyph, volume, network (one glyph, VPN replaces Wi-Fi), Bluetooth, session, and the clock. The clock is the last item and reads like `Nov 24 Tue, 16:07` (`%b %d %a, %H:%M`); the centre is empty.
- Local plugin `swaydots/bar` (`~/.local/share/noctalia/plugins/swaydots-bar`, stowed from `noctalia`) adds two bar widgets: `workspaces` always lists 1–6 (empty ones dimmed), and `media` is a music glyph shown only while a player is playing or paused (`playerctl --follow`).
- Calendar: `60-calendar.toml` sets `dedupe_events = true`, so one Google invite that sits in more than one calendar shows once.
- Display layouts: `$mod+p` runs `~/.local/bin/displays` (package `displays`), which offers `laptop`, `extend`, and `clone` in `noctalia dmenu`; `displays <name>` applies one directly and failures arrive as a notification. The `micahg/nwg-displays` plugin is no longer enabled. Extend places whatever monitor is plugged in to the right at its own resolution. Clone shows a fullscreen copy of the built-in screen on it (`wl-mirror`). `/usr/local/bin/nwg-displays-apply` runs `extra/display-layout.sh` for those three names.
- Power profiles: keep Fedora `tuned-ppd` (do not install `power-profiles-daemon`; they conflict).
- Desktop apps that stay: Thunar, Kate, and Ark. Thunar uses `adw-gtk3-dark`, which reads the Noctalia GTK color names, and Papirus-Dark. Its preferences (volume management, thumbnails, full-colour icons) are set by the restore step `step_thunar_prefs` with `xfconf-query`, not stowed, because xfconfd replaces `thunar.xml` on every write. Open Terminal launches Ghostty (`TerminalEmulator=ghostty` in `~/.config/xfce4/helpers.rc`). `thunar --daemon` watches USB and MTP volumes; gvfs-mtp, gvfs-gphoto2, and gvfs-afc are installed. The xfce4-panel package stays because Thunar links its library, and the panel is not started. Clock is GNOME Clocks (`gnome-clocks`); calculator is GNOME Calculator (`gnome-calculator`); the task manager is Resources (`resources` from Terra). All three are small libadwaita apps and read the same GTK palette. Camera is Snapshot (`snapshot`). Restore uninstalls the Resources Flatpak (`net.nokyan.Resources`) so the Flatpak runtime is not pulled in. KDE Connect pairs a phone; the indicator autostarts and the firewall allows `kdeconnect` (tcp/udp 1714-1764). System Settings, System Monitor, KClock, and Kamoso are removed; they do not work under Sway.
- Notifications: Noctalia owns `org.freedesktop.Notifications`. Mask/remove `dunst`.
- Purge Sway-spin leftovers on restore: Dolphin, rofi, foot.

## Stow

```bash
cd ~/swaydots
git submodule update --init --recursive
stow -v --no-folding sway xdg noctalia nwg-displays displays zsh starship ghostty fonts git codium cursor fastfetch herdr opencode
```

Never stow `extra/`, `.skills/`, `.git`, `.cursor`. Restore: `bash extra/restore-fedora.sh`.
