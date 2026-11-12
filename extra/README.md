# extra

Not stowed.

| Path | Purpose |
|------|---------|
| `restore-fedora.sh` | Fedora + Sway + Noctalia bootstrap (dnf + stow) |
| `firefox_user.js` | Firefox prefs (apply manually) |
| `firefox-policies.json` | Force-installs the Pywalfox extension (`/etc/firefox/policies/policies.json`) |
| `firefox-theme.sh` | Installs the Noctalia host and that policy. Asks for sudo. Restart Firefox after. |
| `sync-noctalia-bar.sh` | Copies the live bar into `noctalia/.config/noctalia/10-bar.toml`. Run it when the repo should match. |
| `50-noctalia-greeter.rules` | Lets the active local user sync the login-screen palette. Restore copies it to `/etc/polkit-1/rules.d/`. |

```bash
bash ~/swaydots/extra/restore-fedora.sh
```
