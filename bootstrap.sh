#!/bin/bash
set -euo pipefail

# ============================================================================
# nix-darwin Bootstrap Script
# Run on a fresh macOS machine:
#   curl -fsSL https://raw.githubusercontent.com/acannizzaro/nix-config/main/bootstrap.sh -o /tmp/bootstrap.sh
#   chmod +x /tmp/bootstrap.sh
#   /tmp/bootstrap.sh
# ============================================================================

REPO_URL="https://github.com/acannizzaro/nix-config.git"
FLAKE_DIR="$HOME/.config/nix-darwin"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ============================================================================
# Step 1: Determine hostname
# ============================================================================

echo ""
info "Enter the hostname for this machine (e.g., personal-mbp, work-mbp):"
read -rp "> " HOSTNAME

if [[ -z "$HOSTNAME" ]]; then
  error "Hostname cannot be empty"
fi

if [[ ! "$HOSTNAME" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
  error "Invalid hostname — use letters, digits, dashes, and underscores only"
fi

ok "Hostname: $HOSTNAME"

# ============================================================================
# Step 2: Xcode Command Line Tools
# ============================================================================

echo ""
if xcode-select -p &>/dev/null; then
  ok "Xcode CLI tools already installed"
else
  info "Installing Xcode Command Line Tools..."
  xcode-select --install
  echo ""
  warn "A dialog will appear. Click 'Install', then press Enter here when done."
  read -rp "Press Enter to continue..."

  xcode-select -p &>/dev/null || error "Xcode CLI tools installation failed"
fi

# ============================================================================
# Step 3: Rosetta 2 (Apple Silicon)
# ============================================================================

echo ""
if /usr/bin/pgrep -q oahd 2>/dev/null; then
  ok "Rosetta 2 already installed"
else
  info "Installing Rosetta 2..."
  softwareupdate --install-rosetta --agree-to-license
  ok "Rosetta 2 installed"
fi

# ============================================================================
# Step 4: Install Nix
# ============================================================================

echo ""
if command -v nix &>/dev/null; then
  ok "Nix already installed"
else
  info "Which Nix distribution would you like to install?"
  echo "  1) Determinate Nix (recommended — managed updates, FlakeHub integration)"
  echo "  2) Upstream Nix (official NixOS distribution)"
  read -rp "Select [1/2]: " NIX_CHOICE

  case "$NIX_CHOICE" in
    1)
      info "Installing Determinate Nix..."
      curl --proto '=https' --tlsv1.2 -sSf -L \
        https://install.determinate.systems/nix | sh -s -- install --no-confirm
      ;;
    2)
      info "Installing upstream Nix..."
      curl --proto '=https' --tlsv1.2 -sSf -L \
        https://install.determinate.systems/nix | sh -s -- install --no-confirm --prefer-upstream-nix
      ;;
    *)
      error "Invalid selection"
      ;;
  esac

  # Source nix in current shell
  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  else
    warn "Could not source nix-daemon.sh — open a new terminal and re-run this script"
    exit 0
  fi

  command -v nix &>/dev/null || error "Nix not found — open a new terminal and re-run"
  ok "Nix installed"
fi

# ============================================================================
# Step 5: Clone config repo
# ============================================================================

echo ""
if [ -d "$FLAKE_DIR" ]; then
  ok "Config repo already exists at $FLAKE_DIR"
else
  info "Cloning config repo..."
  mkdir -p "$(dirname "$FLAKE_DIR")"
  git clone "$REPO_URL" "$FLAKE_DIR"
  ok "Config cloned to $FLAKE_DIR"
fi

cd "$FLAKE_DIR"

# ============================================================================
# Step 6: Ensure hostname exists in flake configuration
# ============================================================================

echo ""

# Check if hostname is already active in darwinConfigurations
if grep -q "^[[:space:]]*${HOSTNAME} = mkDarwinSystem" flake.nix; then
  ok "Hostname '$HOSTNAME' already in darwinConfigurations"

# Check if hostname is commented out
elif grep -q "^[[:space:]]*#.*${HOSTNAME} = mkDarwinSystem" flake.nix; then
  info "Uncommenting '$HOSTNAME' in darwinConfigurations..."
  sed -i "" "s|^[[:space:]]*#[[:space:]]*${HOSTNAME} = mkDarwinSystem|      ${HOSTNAME} = mkDarwinSystem|" flake.nix
  ok "Uncommented $HOSTNAME"

# Hostname doesn't exist — scaffold it
else
  info "Setting up new hostname '$HOSTNAME'..."

  read -rp "Enter a friendly name for this machine (e.g., Anthony's Work MacBook): " COMPUTER_NAME
  if [[ -z "$COMPUTER_NAME" ]]; then
    COMPUTER_NAME="$HOSTNAME"
  fi

  # Create host-specific config file
  if [ ! -f "hosts/${HOSTNAME}.nix" ]; then
    info "Creating hosts/${HOSTNAME}.nix..."
    cat > "hosts/${HOSTNAME}.nix" << NIXEOF
{ pkgs, ... }:

{
  networking.hostName = "${HOSTNAME}";
  networking.computerName = "${COMPUTER_NAME}";

  # Host-specific Homebrew casks
  homebrew.casks = [
  ];
}
NIXEOF
    ok "Created hosts/${HOSTNAME}.nix"
  fi

  # Add to darwinConfigurations in flake.nix (before the closing };)
  info "Adding '$HOSTNAME' to darwinConfigurations..."
  awk -v host="$HOSTNAME" '
    /^[[:space:]]*};[[:space:]]*$/ && !added {
      print "      " host " = mkDarwinSystem { hostname = \"" host "\"; };"
      added = 1
    }
    { print }
  ' flake.nix > flake.nix.tmp && mv flake.nix.tmp flake.nix

  ok "Added $HOSTNAME to darwinConfigurations"
fi

# ============================================================================
# Step 7: Set macOS hostname
# ============================================================================

echo ""
info "Setting macOS hostname to $HOSTNAME..."
sudo scutil --set HostName "$HOSTNAME"
sudo scutil --set LocalHostName "$HOSTNAME"
ok "Hostname set"

# ============================================================================
# Step 8: Bootstrap agenix secrets
# ============================================================================

echo ""
info "Setting up agenix secrets for this machine..."

# Get this machine's host SSH public key
if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
  error "Host SSH key not found at /etc/ssh/ssh_host_ed25519_key"
fi
HOST_KEY=$(ssh-keygen -y -f /etc/ssh/ssh_host_ed25519_key)
ok "Host SSH public key: ${HOST_KEY:0:40}..."

# Update or add hostname in secrets.nix
if grep -q "^  ${HOSTNAME} = " secrets/secrets.nix; then
  info "Hostname '$HOSTNAME' already in secrets.nix — updating host key..."
  sed -i "" "s|  ${HOSTNAME} = \".*\";|  ${HOSTNAME} = \"${HOST_KEY}\";|" secrets/secrets.nix
  ok "Updated host key for $HOSTNAME"
else
  info "Adding new hostname '$HOSTNAME' to secrets.nix..."

  # Add new host variable before 'in' line
  awk -v host="$HOSTNAME" -v key="$HOST_KEY" '
    /^in$/ { print "  " host " = \"" key "\";" }
    { print }
  ' secrets/secrets.nix > secrets/secrets.nix.tmp && mv secrets/secrets.nix.tmp secrets/secrets.nix

  # Add hostname to all publicKeys lists
  sed -i "" "s/ \];/ ${HOSTNAME} \];/g" secrets/secrets.nix

  ok "Added $HOSTNAME to secrets.nix"
fi

echo ""
info "Updated secrets/secrets.nix:"
cat secrets/secrets.nix
echo ""

# Re-encrypt secrets with updated key set
info "To re-encrypt secrets, paste your age recovery private key."
info "Find it in 1Password: op://Private/agenix-key/password"
info "(Open 1Password on your phone or at https://my.1password.com)"
echo ""

TMPKEY=$(mktemp)
chmod 600 "$TMPKEY"
trap 'rm -f "$TMPKEY"' EXIT

read -rsp "Paste the age recovery key (starts with AGE-SECRET-KEY-), then press Enter: " AGE_KEY
echo ""

if [[ ! "$AGE_KEY" =~ ^AGE-SECRET-KEY- ]]; then
  rm -f "$TMPKEY"
  error "Invalid key format — must start with AGE-SECRET-KEY-"
fi

echo "$AGE_KEY" > "$TMPKEY"

info "Re-encrypting secrets..."
cd secrets
if nix run github:ryantm/agenix -- -r -i "$TMPKEY"; then
  ok "Secrets re-encrypted successfully"
else
  rm -f "$TMPKEY"
  error "Re-encryption failed — check that the recovery key is correct"
fi
cd "$FLAKE_DIR"

rm -f "$TMPKEY"

# ============================================================================
# Step 9: First-time nix-darwin build and activation
# ============================================================================

echo ""
info "Building nix-darwin configuration for $HOSTNAME..."

if ! nix build ".#darwinConfigurations.${HOSTNAME}.system"; then
  error "Build failed — check flake.nix for errors"
fi
ok "Build complete"

info "Activating nix-darwin..."
if ! sudo ./result/sw/bin/darwin-rebuild switch --flake .; then
  error "Activation failed"
fi
ok "nix-darwin activated"

# ============================================================================
# Step 10: Switch git remote to SSH
# ============================================================================

echo ""
info "Switching git remote to SSH..."
git remote set-url origin git@github.com:acannizzaro/nix-config.git
ok "Remote switched to SSH (requires 1Password SSH agent — see manual steps)"

# ============================================================================
# Step 11: Host-specific post-install
# ============================================================================

echo ""
if [[ "$HOSTNAME" == "personal-mbp" ]]; then
  info "Running personal machine setup..."

  LOL_INSTALLER=$(find /opt/homebrew/Caskroom/league-of-legends -name "Install League*" -maxdepth 2 2>/dev/null | head -1)
  if [ -n "$LOL_INSTALLER" ]; then
    info "Launching League of Legends installer..."
    open "$LOL_INSTALLER"
  fi

  ok "Personal setup complete"
fi

# ============================================================================
# Done!
# ============================================================================

echo ""
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN} Bootstrap complete!${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo ""
echo "Manual steps remaining (see MANUAL_STEPS.md):"
echo ""
echo "  1. Open a NEW terminal window"
echo ""
echo "  2. Set Firefox as default browser:"
echo "     System Settings > Desktop & Dock > Default web browser > Firefox"
echo ""
echo "  3. Grant Hammerspoon Accessibility permission:"
echo "     System Settings > Privacy & Security > Accessibility > Hammerspoon"
echo ""
echo "  4. Enable 1Password SSH agent:"
echo "     1Password > Settings > Developer > Set up SSH Agent"
echo ""
echo "  5. Add SSH public key to GitHub:"
echo "     Copy from 1Password > https://github.com/settings/ssh/new"
echo ""
echo "  6. Verify FileVault is enabled: fdesetup status"
echo ""
echo "  7. Verify everything:"
echo "     rebuild                  # clean build"
echo "     gh auth status           # GitHub authenticated"
echo "     ssh -T git@github.com   # SSH working"
echo "     fastfetch                # system info"
echo ""
