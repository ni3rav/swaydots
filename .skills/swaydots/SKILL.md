---
name: swaydots
description: >-
  Maintain Fedora Sway + Noctalia Stow dotfiles in ~/swaydots: edit packages,
  add packages, restow, keep a single ~/.zshrc, use extra/restore-fedora.sh.
  User-invoked when changing dotfiles, stowing, or restoring.
disable-model-invocation: true
---

# swaydots

Repo: `~/swaydots`. Stow maps packages into `$HOME`.

## Rules

1. One shell config: stowed `zsh/.zshrc` only. Never `.zshrc.local`.
2. Edit in the repo (live paths are symlinks).
3. Never stow `extra/`, `.skills/`, `.git`, docs, or the runtime `~/.cursor` tree. The `cursor` package may include `cli-config.json` only.
4. Always `stow -v --no-folding <pkgs…>` from repo root.
5. Surgical changes only; match existing style.
6. Thin thread: **Sway = WM/keybinds only**; **Noctalia = bar/launcher/OSD/lock/screenshots**.

Packages: `sway` `xdg` `noctalia` `nwg-displays` `zsh` `starship` `ghostty` `fonts` `git` `codium` `cursor` `fastfetch` `herdr` `opencode`.

See [reference.md](reference.md) and [workflows.md](workflows.md).

## After changes

```bash
cd ~/swaydots
stow -n -v --no-folding <pkg>…
stow -v --no-folding <pkg>…
```

Sway → `swaymsg reload`. Fonts → `fc-cache -fv`. Zsh plugins → `git submodule update --init --recursive`.

If Stow hits a real file: move aside (`*.pre-stow`), restow. Don’t `--adopt` unless asked.

Fresh install: `bash extra/restore-fedora.sh`. Commit only when asked.
