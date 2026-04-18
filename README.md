# nix-config

Fully declarative macOS configuration using [nix-darwin](https://github.com/LnL7/nix-darwin), [Home Manager](https://github.com/nix-community/home-manager), and [agenix](https://github.com/ryantm/agenix) for secrets management.

Everything — system settings, packages, dotfiles, shell configuration, dev toolchains, and GUI apps — is defined in Nix and reproducible across machines.

## Architecture

| Layer | Tool | Purpose |
|-------|------|---------|
| System | nix-darwin | macOS defaults, fonts, PAM, system packages |
| User | Home Manager | Dotfiles, shell, editor, dev tools |
| GUI Apps | nix-homebrew | Casks for apps that don't work from nixpkgs on macOS |
| Secrets | agenix | Encrypted secrets decrypted at activation via host SSH key |
| Rust | fenix | Nix-native Rust toolchain (replaces rustup) |

## Repository Structure

```
.
├── flake.nix                 # Entry point — inputs, outputs, host definitions
├── flake.lock                # Pinned dependency versions
├── bootstrap.sh              # Fresh machine setup script
├── hosts/
│   ├── common.nix            # Shared system config, agenix secrets, Touch ID sudo
│   └── personal-mbp.nix      # Host-specific casks and networking
├── modules/
│   ├── defaults.nix          # macOS System Settings (dock, finder, trackpad)
│   ├── homebrew.nix          # Shared Homebrew casks (Ghostty, 1Password, etc.)
│   └── system.nix            # Shell, fonts, timezone
├── home/
│   ├── common.nix            # HM entry point, packages, Ghostty/Hammerspoon config
│   ├── shell.nix             # zsh, starship prompt, fzf, aliases
│   ├── git.nix               # Git config, SSH signing, delta, 1Password SSH agent
│   ├── editor.nix            # Neovim + all LSP servers/formatters (replaces Mason)
│   ├── dev.nix               # Rust (fenix), Python, OpenTofu, Nix tooling
│   ├── scripts.nix           # Project scaffolding (mkpy, mkrs, mktf, mcp-init)
│   ├── firefox.nix           # Firefox policies, extensions, privacy hardening
│   ├── fastfetch.nix         # System info display
│   ├── claude-code.nix       # Claude Code settings and permissions
│   ├── gh.nix                # GitHub CLI auth via agenix
│   ├── hammerspoon/          # Window management keybindings
│   ├── fastfetch/            # fastfetch config
│   └── nvim/                 # Neovim config (lazy.nvim, custom Synthwave theme)
├── secrets/
│   ├── secrets.nix           # Public key mappings for agenix
│   ├── github-token.age      # Encrypted GitHub PAT
│   └── env-secrets.age       # Encrypted environment variables
├── templates/
│   ├── python/               # Python project template (uv, ruff, ty)
│   ├── rust/                 # Rust project template (fenix)
│   └── terraform/            # OpenTofu project template
└── overlays/
    └── default.nix
```

## Quick Start

### Existing Machine

```bash
rebuild          # sudo darwin-rebuild switch --flake ~/.config/nix-darwin
rollback         # sudo darwin-rebuild switch --rollback
nix-gc           # nix-collect-garbage --delete-older-than 30d
```

### Fresh Machine

```bash
curl -fsSL https://raw.githubusercontent.com/alexander-barrere/nix-config/main/bootstrap.sh -o /tmp/bootstrap.sh
chmod +x /tmp/bootstrap.sh
/tmp/bootstrap.sh
```

The bootstrap script handles: Xcode CLI tools, Rosetta 2, Nix installation, repo cloning, hostname setup, agenix secret re-encryption, and first build. See [bootstrap.sh](bootstrap.sh) for details.

## Adding a New Machine

The bootstrap script handles this automatically. When you enter a hostname that doesn't exist in the config, it will:

1. Create `hosts/<hostname>.nix` with networking config
2. Add the hostname to `darwinConfigurations` in `flake.nix`
3. Add the host's SSH public key to `secrets/secrets.nix`
4. Re-encrypt secrets so the new machine can decrypt them

## Secrets Management

Secrets are encrypted with [agenix](https://github.com/ryantm/agenix) using age encryption. Each secret is encrypted to a set of public keys (user SSH key, host SSH key, recovery age key). At activation, agenix decrypts secrets using the host SSH key at `/etc/ssh/ssh_host_ed25519_key`.

```bash
age-edit github-token.age    # Edit a secret (pulls recovery key from 1Password)
```

The `recovery` age key is stored in 1Password (`op://Private/agenix-key/password`) and is used for editing and re-encryption. It is never stored on disk permanently.

## Project Scaffolding

Create new projects with dev shells and tooling pre-configured:

```bash
mkpy my-project    # Python (uv, ruff, ty, flake.nix, .envrc, CLAUDE.md)
mkrs my-project    # Rust (fenix, cargo, flake.nix, .envrc, CLAUDE.md)
mktf my-project    # OpenTofu (flake.nix, .envrc, main.tf, CLAUDE.md)
mcp-init           # Add MCP servers (Context7 + Serena) to current project
rmpj my-project    # Remove a project (handles .direnv permissions)
```

## Key Decisions

- **Nix-only CLI tools**: All CLI tools come from nixpkgs. Homebrew is only used for GUI casks that don't work from nixpkgs on macOS (Ghostty, 1Password, etc.)
- **fenix over rustup**: Rust toolchain is managed declaratively through Nix, not rustup
- **OpenTofu over Terraform**: Avoids BSL license. `terraform` and `tf` are aliased to `tofu`
- **1Password SSH agent**: All SSH keys are managed by 1Password, never stored on disk. Commit signing uses the same SSH key
- **No Mason in Neovim**: All LSP servers, formatters, and linters are installed via Nix in `editor.nix`
- **Firefox via nixpkgs**: Policies, extensions (uBlock Origin, 1Password), and privacy hardening are all declarative. A ditto activation script copies the app to `/Applications/` for Spotlight

## Terminal & Theme

- **Terminal**: Ghostty with Hack Nerd Font
- **Theme**: Synthwave palette — consistent across Neovim, bat, starship, and fastfetch
- **Prompt**: Starship with agnoster-inspired powerline segments
- **Shell**: zsh with vi mode, autosuggestions, syntax highlighting

## Manual Steps After Bootstrap

Some things can't be automated:

- Set Firefox as default browser (System Settings > Desktop & Dock)
- Grant Hammerspoon Accessibility permission (System Settings > Privacy & Security)
- Enable 1Password SSH agent (1Password > Settings > Developer)
- Add SSH public key to GitHub as [authentication](https://github.com/settings/keys) and [signing](https://github.com/settings/keys) key
- Verify FileVault is enabled (`fdesetup status`)
