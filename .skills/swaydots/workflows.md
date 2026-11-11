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

## Restore / validate

```bash
bash ~/swaydots/extra/restore-fedora.sh
cd ~/swaydots
stow -n -v --no-folding sway xdg noctalia zsh starship ghostty fonts git code cursor
sway -C -c ~/.config/sway/config
readlink -f ~/.config/sway/config
```

Greeter cutover (destructive to current DM):

```bash
SWAYDOTS_ENABLE_GREETD=1 bash ~/swaydots/extra/restore-fedora.sh
```
