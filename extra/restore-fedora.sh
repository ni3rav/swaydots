#!/usr/bin/env bash
# bash ~/swaydots/extra/restore-fedora.sh
# Fedora + Sway (WM) + Noctalia (shell). Progressive — grow steps as packages land.

set -u
set -o pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/swaydots}"
FAILED=()
STARTED_AT=$(date -Iseconds)
ZSHRC_TRACKED="$DOTFILES_DIR/zsh/.zshrc"

log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '  \033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[1;33m!\033[0m %s\n' "$*"; }
err()  { printf '  \033[1;31m✗\033[0m %s\n' "$*"; }

need_cmd() { command -v "$1" >/dev/null 2>&1; }

export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${HOME}/.bun/bin:${HOME}/.opencode/bin:${HOME}/.cursor/bin:${PATH}"

refresh_path() {
  export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${HOME}/.bun/bin:${HOME}/.opencode/bin:${HOME}/.cursor/bin:${PATH}"
  # shellcheck disable=SC1090
  [[ -f "${HOME}/.cargo/env" ]] && source "${HOME}/.cargo/env"
  export BUN_INSTALL="${HOME}/.bun"
  export PATH="${BUN_INSTALL}/bin:${PATH}"
  if [[ -s "${HOME}/.nvm/nvm.sh" ]]; then
    # shellcheck disable=SC1090
    source "${HOME}/.nvm/nvm.sh"
  fi
}

guard_zshrc() {
  if [[ -f "$ZSHRC_TRACKED" ]]; then
    cp -a "$ZSHRC_TRACKED" /tmp/swaydots-zshrc.guard
  fi
}

restore_zshrc_if_clobbered() {
  [[ -f /tmp/swaydots-zshrc.guard ]] || return 0
  if ! cmp -s /tmp/swaydots-zshrc.guard "$ZSHRC_TRACKED" 2>/dev/null; then
    warn "restoring tracked zsh/.zshrc after installer modified it"
    cp -a /tmp/swaydots-zshrc.guard "$ZSHRC_TRACKED"
  fi
  if [[ -e "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
    warn "installer replaced ~/.zshrc symlink; removing so stow can relink"
    mv "$HOME/.zshrc" "$HOME/.zshrc.installer-clobber"
  fi
}

run_step() {
  local title=$1
  shift
  log "$title"
  if "$@"; then
    ok "$title"
    return 0
  fi
  err "$title"
  FAILED+=("$title")
  return 0
}

have_copr() {
  dnf copr list 2>/dev/null | grep -Fq "$1"
}

ensure_copr() {
  local name=$1
  if have_copr "$name"; then
    ok "COPR already enabled: $name"
    return 0
  fi
  sudo dnf copr enable -y "$name"
}

configure_dnf() {
  sudo tee /etc/dnf/dnf.conf >/dev/null <<'EOF'
[main]
max_parallel_downloads=10
fastestmirror=True
timeout=30
minrate=10k
EOF
}

step_dnf_config() { configure_dnf; }
step_dnf_upgrade() { sudo dnf upgrade -y; }

step_core_packages() {
  sudo dnf install -y --setopt=install_weak_deps=False \
    git curl wget stow zsh zoxide fzf eza bat gh \
    golang fd-find ripgrep fontconfig util-linux-user flatpak \
    python3-pip \
    sway sway-systemd xdg-user-dirs \
    noctalia \
    dolphin kate qt6ct kio-extras ark \
    gnome-clocks snapshot \
    gvfs-mtp gvfs-gphoto2 gvfs-afc gvfs-smb libmtp \
    blueman brightnessctl pavucontrol pulseaudio-utils \
    python3-gobject \
    playerctl \
    fastfetch \
    xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
    jq \
    openssh-clients \
    greetd
}

step_starship() {
  ensure_copr "atim/starship"
  sudo dnf install -y starship
}

step_zsh_shell() {
  local zsh_path
  zsh_path=$(command -v zsh)
  [[ -n "$zsh_path" ]] || { err "zsh not installed"; return 1; }
  if [[ "${SHELL:-}" == "$zsh_path" ]]; then
    ok "login shell already zsh"
    return 0
  fi
  sudo chsh -s "$zsh_path" "$USER"
}

step_golang() {
  need_cmd go || sudo dnf install -y golang
  go version
}

step_rust() {
  if need_cmd rustc && need_cmd cargo; then
    ok "rust already installed: $(rustc --version)"
  else
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
      | sh -s -- -y --no-modify-path
  fi
  refresh_path
  rustc --version
  cargo --version
}

step_ghostty() {
  ensure_copr "scottames/ghostty"
  sudo dnf install -y ghostty
}

step_noctalia() {
  need_cmd noctalia || sudo dnf install -y noctalia
  noctalia --version 2>/dev/null || ok "noctalia installed"
}

step_kdeconnect() {
  sudo dnf install -y kde-connect
  if systemctl is-active --quiet firewalld; then
    sudo firewall-cmd --permanent --add-service=kdeconnect
    sudo firewall-cmd --reload
    ok "firewall allows KDE Connect"
  else
    warn "firewalld is inactive; KDE Connect needs tcp/udp 1714-1764"
  fi
}

step_nwg_displays() {
  sudo dnf install -y nwg-displays wl-mirror
  sudo install -m 755 "$DOTFILES_DIR/extra/nwg-displays-apply" /usr/local/bin/nwg-displays-apply
  if need_cmd noctalia && noctalia msg plugins enable micahg/nwg-displays >/dev/null 2>&1; then
    ok "nwg-displays plugin enabled"
  else
    warn "nwg-displays plugin enables once Noctalia is up"
  fi
}

step_notifications_noctalia() {
  sudo dnf remove -y dunst 2>/dev/null || true
  systemctl --user stop dunst.service 2>/dev/null || true
  systemctl --user mask dunst.service 2>/dev/null || true
  systemctl --user daemon-reload 2>/dev/null || true
  ok "dunst masked; Noctalia owns notifications"
}

step_purge_stale() {
  sudo dnf remove -y --setopt=install_weak_deps=False \
    Thunar thunar-archive-plugin tumbler xarchiver \
    rofi rofi-themes \
    foot \
    xfce4-panel \
    plasma-systemsettings plasma-systemmonitor kclock kamoso \
    mousepad xfce4-terminal \
    dmenu bemenu wofi \
    2>/dev/null || true

  local stale=(
    "$HOME/.config/Thunar"
    "$HOME/.config/xfce4"
    "$HOME/.config/rofi"
    "$HOME/.config/foot"
    "$HOME/.config/xarchiver"
  )
  local p
  for p in "${stale[@]}"; do
    if [[ -e "$p" || -L "$p" ]]; then
      rm -rf "$p"
      ok "removed stale $p"
    fi
  done
}

step_noctalia_greeter_pkgs() {
  if rpm -q terra-release >/dev/null 2>&1; then
    ok "terra-release already installed"
  else
    sudo dnf install -y --nogpgcheck \
      --repofrompath "terra,https://repos.fyralabs.com/terra$(rpm -E %fedora)" \
      terra-release
  fi
  sudo dnf install -y noctalia-greeter greetd
  need_cmd noctalia-greeter-session \
    || { err "noctalia-greeter-session missing after install"; return 1; }
  sudo mkdir -p /etc/polkit-1/rules.d
  sudo cp "$DOTFILES_DIR/extra/50-noctalia-greeter.rules" /etc/polkit-1/rules.d/50-noctalia-greeter.rules
  ok "greeter palette sync allowed for the active local user"
}

step_greetd_cutover() {
  if [[ "${SWAYDOTS_ENABLE_GREETD:-0}" != "1" ]]; then
    warn "skip greetd cutover (set SWAYDOTS_ENABLE_GREETD=1 to enable)"
    return 0
  fi

  need_cmd noctalia-greeter-session \
    || { err "noctalia-greeter-session not on PATH"; return 1; }

  if [[ -x /usr/share/noctalia-greeter/setup_greeter_system.sh ]]; then
    sudo bash /usr/share/noctalia-greeter/setup_greeter_system.sh || true
  fi
  sudo noctalia-greeter-apply-appearance --setup-system 2>/dev/null || true

  sudo mkdir -p /etc/greetd
  if [[ -f /etc/greetd/config.toml ]]; then
    sudo cp -a /etc/greetd/config.toml "/etc/greetd/config.toml.pre-swaydots"
  fi
  sudo tee /etc/greetd/config.toml >/dev/null <<'EOF'
[terminal]
vt = 1

[default_session]
command = "/usr/bin/noctalia-greeter-session"
user = "greetd"
EOF

  sudo systemctl disable --now sddm.service 2>/dev/null || true
  sudo systemctl disable --now gdm.service 2>/dev/null || true
  sudo systemctl disable --now lightdm.service 2>/dev/null || true
  sudo systemctl enable greetd.service
  warn "greetd enabled — reboot to use Noctalia greeter (do not stop the live DM mid-session)"
}

step_charm() {
  if [[ ! -f /etc/yum.repos.d/charm.repo ]]; then
    printf '%s\n' \
      '[charm]' \
      'name=Charm' \
      'baseurl=https://repo.charm.sh/yum/' \
      'enabled=1' \
      'gpgcheck=1' \
      'gpgkey=https://repo.charm.sh/yum/gpg.key' \
      | sudo tee /etc/yum.repos.d/charm.repo >/dev/null
  fi
  sudo dnf install -y glow
}

step_bun() {
  guard_zshrc
  if need_cmd bun; then
    ok "bun already installed: $(bun --version)"
  else
    curl -fsSL https://bun.sh/install | bash
  fi
  restore_zshrc_if_clobbered
  refresh_path
  bun --version
}

step_nvm_node_pnpm() {
  guard_zshrc
  export NVM_DIR="${HOME}/.nvm"
  if [[ ! -s "${NVM_DIR}/nvm.sh" ]]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh \
      | PROFILE=/dev/null bash
  else
    ok "nvm already present"
  fi
  restore_zshrc_if_clobbered
  set +u
  # shellcheck disable=SC1090
  source "${NVM_DIR}/nvm.sh"
  nvm install --lts
  nvm install node || true
  local node_ver
  node_ver=$(nvm version node 2>/dev/null || echo "")
  if [[ "$node_ver" == *alpha* || "$node_ver" == *beta* || "$node_ver" == *rc* ]]; then
    warn "nvm 'node' is prerelease ($node_ver); removing and defaulting to LTS"
    nvm use --lts
    nvm uninstall "$node_ver" || true
  fi
  nvm alias default 'lts/*'
  nvm use default
  set -u

  export PNPM_HOME="${HOME}/.local/share/pnpm"
  export PATH="${PNPM_HOME}/bin:${PATH}"
  if need_cmd pnpm; then
    ok "pnpm already installed: $(pnpm --version)"
  else
    guard_zshrc
    curl -fsSL https://get.pnpm.io/install.sh | SHELL=zsh PNPM_HOME="$PNPM_HOME" bash -
    restore_zshrc_if_clobbered
    if [[ -e "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
      warn "pnpm replaced ~/.zshrc symlink; restoring stow link"
      rm -f "$HOME/.zshrc"
      [[ -d "$DOTFILES_DIR/zsh" ]] && (cd "$DOTFILES_DIR" && stow -v --no-folding zsh)
    fi
  fi
  refresh_path
  export PATH="${PNPM_HOME}/bin:${PATH}"
  node --version
  pnpm --version
}

step_uv() {
  guard_zshrc
  if need_cmd uv; then
    ok "uv already installed: $(uv --version)"
  else
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi
  restore_zshrc_if_clobbered
  refresh_path
  uv --version
}

step_opencode() {
  guard_zshrc
  if need_cmd opencode; then
    ok "opencode already installed"
  else
    curl -fsSL https://opencode.ai/v2/install | bash -s -- --no-modify-path
  fi
  restore_zshrc_if_clobbered
  refresh_path
  need_cmd opencode && opencode --version || true
}

ensure_codium_profile() {
  local name="$1"
  if codium --profile "$name" --list-extensions >/dev/null 2>&1; then
    return 0
  fi
  local seed
  seed=$(mktemp -d)
  codium --profile "$name" "$seed" >/dev/null 2>&1 || true
  sleep 1
}

install_codium_profile() {
  local name="$1"
  local file="$DOTFILES_DIR/codium/sync/profiles/$name/data/extensions.yml"
  [[ -f "$file" ]] || { warn "codium: no extension list for $name"; return 0; }
  ensure_codium_profile "$name"
  local id
  while read -r id; do
    [[ -n "$id" ]] || continue
    codium --profile "$name" --install-extension "$id" \
      || warn "codium: $name did not install $id"
  done < <(awk '/^[[:space:]]*- id: / { print $3 }' "$file")
  python3 - "$name" << 'PY'
import json, os, sys
from pathlib import Path
name = sys.argv[1]
home = Path.home()
storage = home / ".config/VSCodium/User/globalStorage/storage.json"
data = json.loads(storage.read_text())
loc = ""
for item in data.get("userDataProfiles", []):
    if item.get("name") == name:
        item["useDefaultFlags"] = {
            "settings": True,
            "keybindings": True,
            "tasks": True,
            "snippets": True,
        }
        loc = item["location"]
if loc:
    storage.write_text(json.dumps(data, indent=4) + "\n")
    profile = home / ".config/VSCodium/User/profiles" / loc
    profile.mkdir(parents=True, exist_ok=True)
    os.symlink("../../settings.json", profile / "settings.json") if not (profile / "settings.json").exists() else None
    os.symlink("../../keybindings.json", profile / "keybindings.json") if not (profile / "keybindings.json").exists() else None
    sync = profile / "globalStorage/zokugun.sync-settings"
    sync.mkdir(parents=True, exist_ok=True)
    yml = sync / "settings.yml"
    if not yml.exists():
        yml.write_text(
            'hostname: ""\n'
            f"profile: {name}\n"
            "repository:\n"
            "  type: file\n"
            "  path: ~/swaydots/codium/sync\n"
        )
        os.chmod(yml, 0o600)
PY
}

install_codium_default() {
  local file="$DOTFILES_DIR/codium/sync/profiles/dev/data/extensions.yml"
  [[ -f "$file" ]] || { warn "codium: no extension list for the default profile"; return 0; }
  local id
  while read -r id; do
    [[ -n "$id" ]] || continue
    codium --install-extension "$id" \
      || warn "codium: default profile did not install $id"
  done < <(awk '/^[[:space:]]*- id: / { print $3 }' "$file")
}

step_codium() {
  sudo rm -f /etc/yum.repos.d/vscode.repo
  if rpm -q code >/dev/null 2>&1; then
    sudo dnf remove -y code
  fi
  sudo dnf install -y codium
  need_cmd codium
  codium --install-extension zokugun.sync-settings
  install_codium_default
  install_codium_profile jupyter
}

step_cursor_cli() {
  guard_zshrc
  curl -fsS https://cursor.com/install | bash
  restore_zshrc_if_clobbered
  refresh_path
  if need_cmd agent; then
    ok "cursor agent $(agent --version 2>/dev/null || echo installed)"
    return 0
  fi
  err "cursor agent binary not found on PATH"
  return 1
}

step_flatpaks() {
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak install -y flathub com.obsproject.Studio
  flatpak install -y flathub org.onlyoffice.desktopeditors
  flatpak install -y flathub net.nokyan.Resources
}

step_github_cli() {
  need_cmd gh || sudo dnf install -y gh
  gh --version
}

step_papirus_icons() {
  sudo dnf install -y papirus-icon-theme
  gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
  if need_cmd kwriteconfig6; then
    kwriteconfig6 --file kdeglobals --group Icons --key Theme Papirus-Dark
  elif need_cmd kwriteconfig5; then
    kwriteconfig5 --file kdeglobals --group Icons --key Theme Papirus-Dark
  fi
}

step_firefox_theme() {
  bash "$DOTFILES_DIR/extra/firefox-theme.sh"
  ok "Pywalfox host installed; Firefox force-installs the extension on next start"
}

step_dotfiles() {
  [[ -d "$DOTFILES_DIR" ]] || { err "DOTFILES_DIR missing: $DOTFILES_DIR"; return 1; }
  cd "$DOTFILES_DIR"

  if [[ -d .git ]]; then
    git submodule update --init --recursive 2>/dev/null || true
  fi

  rm -f "$HOME/.zshrc.local"

  if [[ -e "$HOME/.zshrc" && ! -L "$HOME/.zshrc" && -d "$DOTFILES_DIR/zsh" ]]; then
    warn "moving real ~/.zshrc aside so stow can link"
    mv "$HOME/.zshrc" "$HOME/.zshrc.pre-restore"
  fi

  if [[ -e "$HOME/.config/mimeapps.list" && ! -L "$HOME/.config/mimeapps.list" ]]; then
    warn "moving real mimeapps.list aside so stow can link"
    mv "$HOME/.config/mimeapps.list" "$HOME/.config/mimeapps.list.pre-restore"
  fi

  local pkgs=()
  local p
  for p in sway xdg noctalia nwg-displays ghostty zsh starship fonts git codium cursor fastfetch herdr opencode; do
    [[ -d "$DOTFILES_DIR/$p" ]] && pkgs+=("$p")
  done
  ((${#pkgs[@]})) || { err "no stow packages found under $DOTFILES_DIR"; return 1; }

  stow -v --no-folding "${pkgs[@]}"

  systemctl --user daemon-reload 2>/dev/null || true
  systemctl --user start xdg-desktop-portal.service xdg-desktop-portal-wlr.service 2>/dev/null || true

  if [[ -d "$DOTFILES_DIR/fonts" ]]; then
    fc-cache -fv
    fc-list : family | grep -qi 'JetBrainsMono' \
      || { err "JetBrainsMono Nerd Font not visible to fontconfig"; return 1; }
    ok "fonts: JetBrainsMono Nerd Font available"
  fi

  if [[ -d "$DOTFILES_DIR/zsh" ]]; then
    [[ -L "$HOME/.zshrc" ]] || { err "~/.zshrc is not a symlink to stowed zsh/.zshrc"; return 1; }
    [[ ! -e "$HOME/.zshrc.local" ]] || { err ".zshrc.local must not exist"; return 1; }
  fi

  [[ -L "$HOME/.config/sway/config" ]] \
    || { err "~/.config/sway/config is not a stow symlink"; return 1; }
  ok "sway config stowed"

  if need_cmd noctalia && noctalia msg templates-apply >/dev/null 2>&1; then
    ok "noctalia templates applied (gtk, qt, ghostty, sway)"
  else
    warn "noctalia templates not applied; they run once Noctalia is up"
  fi
}

main() {
  log "swaydots restore starting ($STARTED_AT)"
  log "DOTFILES_DIR=$DOTFILES_DIR"
  guard_zshrc

  run_step "Configure /etc/dnf/dnf.conf" step_dnf_config
  run_step "Upgrade system packages" step_dnf_upgrade
  run_step "Install core packages (sway + noctalia)" step_core_packages
  run_step "Install KDE Connect" step_kdeconnect
  run_step "Install nwg-displays" step_nwg_displays
  run_step "Purge Sway-spin leftovers (rofi/Thunar/foot/…)" step_purge_stale
  run_step "Install Noctalia (ensure)" step_noctalia
  run_step "Hand notifications to Noctalia" step_notifications_noctalia
  run_step "Install Ghostty (COPR)" step_ghostty
  run_step "Install Noctalia Greeter pkgs (Terra)" step_noctalia_greeter_pkgs
  run_step "Optional greetd cutover" step_greetd_cutover
  run_step "Install starship from COPR" step_starship
  run_step "Set zsh as login shell" step_zsh_shell
  run_step "Verify Go toolchain" step_golang
  run_step "Install Rust (rustup)" step_rust
  run_step "Install Charm (glow)" step_charm
  run_step "Install Bun" step_bun
  run_step "Install NVM, Node LTS/Current, pnpm" step_nvm_node_pnpm
  run_step "Install uv" step_uv
  run_step "Install OpenCode" step_opencode
  run_step "Install VSCodium" step_codium
  run_step "Install Cursor agent CLI" step_cursor_cli
  run_step "Install Flatpak apps (OBS, OnlyOffice, Resources)" step_flatpaks
  run_step "Install GitHub CLI" step_github_cli
  run_step "Install Papirus icon theme" step_papirus_icons
  run_step "Theme Firefox with Pywalfox" step_firefox_theme
  run_step "Stow packages + validate sway" step_dotfiles

  restore_zshrc_if_clobbered
  rm -f "$HOME/.zshrc.local"

  printf '\n'
  if ((${#FAILED[@]})); then
    warn "Finished with ${#FAILED[@]} failed step(s):"
    for f in "${FAILED[@]}"; do err "$f"; done
    printf '\nRe-run the script to retry failed steps.\n'
    return 1
  fi

  ok "Restore finished successfully."
  printf 'Sway = WM/keybinds; Noctalia = bar/launcher/OSD/lock.\n'
  printf 'Greeter cutover: SWAYDOTS_ENABLE_GREETD=1 bash ~/swaydots/extra/restore-fedora.sh\n'
  printf 'Reload: swaymsg reload (inside a sway session).\n'

  if need_cmd gh; then
    if gh auth status -h github.com >/dev/null 2>&1; then
      ok "gh already logged in"
    elif [[ "${SWAYDOTS_GH_LOGIN:-0}" == "1" ]]; then
      log "GitHub CLI login (post-success)"
      gh auth login
    else
      warn "gh not logged in (set SWAYDOTS_GH_LOGIN=1 to run gh auth login)"
    fi
  fi
}

main "$@"
