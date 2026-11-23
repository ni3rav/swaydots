# Workflows

## Edit a package

1. Edit under `~/swaydots/<pkg>/…`
2. `stow -n -v --no-folding <pkg>` then `stow -v --no-folding <pkg>` if needed
3. Reload (`swaymsg reload` / shell / `fc-cache`)
4. Commit only if asked

## Add a package

Mirror `$HOME` under a new top-level dir, stow it, update `reference.md` + restore `step_dotfiles` package list. Non-stowed stuff goes in `extra/` or `.stow-local-ignore`.

## Clobbered ~/.zshrc

```bash
rm -f ~/.zshrc.local
[[ -f ~/.zshrc && ! -L ~/.zshrc ]] && mv ~/.zshrc ~/.zshrc.installer-clobber
cd ~/swaydots && stow -v --no-folding zsh
```

## Save the Noctalia bar

Noctalia copies the live bar on startup and when the palette changes. To copy it now:

```bash
bash ~/.config/noctalia/hooks/sync-bar.sh
```

## Restore / validate

```bash
bash ~/swaydots/extra/restore-fedora.sh
cd ~/swaydots
stow -n -v --no-folding sway xdg noctalia nwg-displays displays zsh starship ghostty fonts git codium cursor fastfetch herdr opencode
sway -C -c ~/.config/sway/config
readlink -f ~/.config/sway/config
```

Greeter cutover (destructive to current DM):

```bash
SWAYDOTS_ENABLE_GREETD=1 bash ~/swaydots/extra/restore-fedora.sh
```
