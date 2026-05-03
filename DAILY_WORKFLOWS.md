# Daily nix-darwin workflows

This repo is the source of truth for this Mac. The goal is simple: long-lived system state goes in Nix, project-specific mess goes in project flakes/dev shells, and secrets go in agenix.

Host/user assumptions in this document:

- Host: `tanngrisnir`
- User: `thor`
- Repo: `~/.config/nix-darwin`
- Shell: zsh via Home Manager
- Package stack: Determinate Nix + nix-darwin + Home Manager + nix-homebrew + agenix

## Golden rules

1. **Do not hand-edit Home Manager-managed dotfiles.**
   Files like `~/.zshrc` and `~/.zshenv` are generated from Nix and usually symlink into `/nix/store`.

2. **CLI tools should usually come from Nix.**
   Add durable CLI tools to `home/common.nix`, `home/dev.nix`, `home/editor.nix`, or a focused Home Manager module.

3. **Homebrew is mostly for GUI apps/casks.**
   Use `modules/homebrew.nix` for shared GUI apps and `hosts/tanngrisnir.nix` for host-specific GUI apps.

4. **Project dependencies should stay inside the project.**
   Use flakes + direnv for random GitHub repos, language toolchains, and project-specific services.

5. **Secrets never go in plaintext Git.**
   Put secrets in `secrets/env-secrets.age` with `age-edit env-secrets.age`. Commit only encrypted `.age` files.

6. **Build before committing.**
   Always run `darwin-rebuild build --flake ~/.config/nix-darwin` before committing changes.

7. **Activate intentionally.**
   Use `rebuild` or `sudo darwin-rebuild switch --flake ~/.config/nix-darwin` only after the config builds.

## Useful aliases

Defined in `home/shell.nix`:

```sh
nixd      # cd ~/.config/nix-darwin
gaa       # git add -A
rebuild   # sudo darwin-rebuild switch --flake ~/.config/nix-darwin
rollback  # sudo darwin-rebuild switch --rollback
nix-gc    # nix-collect-garbage --delete-older-than 30d
nixup     # nixd && nix flake update && gaa && rebuild
```

Daily pattern:

```sh
nixd
git status
# edit files
nixfmt path/to/file.nix
darwin-rebuild build --flake ~/.config/nix-darwin
git diff
gaa
git commit -m "describe change"
rebuild
```

If activation breaks something:

```sh
rollback
```

## Repository map

Important files and when to edit them:

- `flake.nix` — inputs, host definitions, flake templates, special args.
- `flake.lock` — pinned dependency versions; updated by `nix flake update`.
- `hosts/common.nix` — shared nix-darwin system config, user, Touch ID sudo, agenix declarations.
- `hosts/tanngrisnir.nix` — this Mac's hostname and host-specific casks.
- `modules/homebrew.nix` — shared Homebrew casks/formulae.
- `modules/defaults.nix` — macOS defaults: Dock, Finder, trackpad, global preferences.
- `modules/system.nix` — system-level macOS/Nix settings.
- `home/common.nix` — Home Manager entry point, shared user packages, Ghostty config, imports.
- `home/shell.nix` — zsh, aliases, history, keybinds, autosuggestions, Starship.
- `home/dev.nix` — durable dev tools such as Python, uv, ruff, ty, Nix tools, Rust via fenix.
- `home/editor.nix` — Neovim, LSP servers, formatters, linters.
- `home/scripts.nix` — helper scripts like `age-edit`, `mkpy`, `mkrs`, `mktf`, `mcp-init`.
- `home/hermes.nix` — declarative Hermes Agent package and gateway LaunchAgent.
- `secrets/secrets.nix` — public recipients for agenix encryption. Safe to commit.
- `secrets/env-secrets.age` — encrypted environment variables. Safe to commit; never print decrypted contents.
- `templates/` — reusable flake templates for new projects.

## Modifying `.config/` and dotfiles

### Shell config

Do **not** edit `~/.zshrc` directly. It is generated from `home/shell.nix`.

Examples:

Add an alias:

```nix
programs.zsh.shellAliases = {
  gs = "git status";
  myalias = "some command";
};
```

Add zsh initialization logic:

```nix
programs.zsh.initContent = ''
  # your zsh code here
'';
```

Add non-secret session variables:

```nix
programs.zsh.sessionVariables = {
  LANG = "en_US.UTF-8";
  LESS = "-R";
};
```

For long-lived, non-secret env vars that should apply broadly, prefer Home Manager session variables. For secrets, use agenix instead.

### Ghostty config

Ghostty config is declared in `home/common.nix`:

```nix
xdg.configFile."ghostty/config".text = ''
  font-family = MesloLGS NF
  font-size = 12
  theme = Synthwave Everything
'';
```

Validate Ghostty config before activation:

```sh
/Applications/Ghostty.app/Contents/MacOS/ghostty +validate-config --config-file=/tmp/ghostty-config-from-nix
```

If extracting from Nix is annoying, build first and inspect the generated Home Manager files.

### Neovim/editor config

Edit `home/editor.nix` and files under `home/nvim/`.

Rule of thumb: do not use Mason to install LSP servers. Install LSPs/formatters/linters declaratively through Nix so the editor is reproducible.

### Hammerspoon config

Hammerspoon config lives under:

```sh
home/hammerspoon/
```

After changing Hammerspoon files:

```sh
darwin-rebuild build --flake ~/.config/nix-darwin
rebuild
```

Then reload Hammerspoon if needed.

## Trying new GitHub repos and random toolchains

Use a disposable project shell instead of globally installing dependencies.

### First choice: existing project already has a flake

```sh
git clone <repo-url>
cd <repo>
direnv allow
nix develop
```

If it has `.envrc` with `use flake`, `direnv allow` should auto-load the dev environment whenever you enter the repo.

### If the repo does not have a flake

Use one of your templates or create a local flake.

Python:

```sh
mkpy my-python-test
cd my-python-test
# copy or clone the repo contents here, or adapt the generated flake
```

Rust:

```sh
mkrs my-rust-test
cd my-rust-test
```

Terraform/OpenTofu:

```sh
mktf my-infra-test
cd my-infra-test
```

### For a one-off cloned repo

A practical pattern:

```sh
git clone <repo-url>
cd <repo>
cat > flake.nix <<'EOF'
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          git
          curl
          jq
          nodejs
          python312
          uv
        ];
      };
    };
}
EOF

echo 'use flake' > .envrc
direnv allow
```

Then add/remove packages from that local `flake.nix` as you learn what the repo needs.

### Handling install scripts

Avoid this if possible:

```sh
curl https://example.com/install.sh | bash
```

Better:

```sh
curl -fsSL https://example.com/install.sh -o /tmp/install.sh
less /tmp/install.sh
bash /tmp/install.sh
```

Then inspect what it changed:

```sh
git status
ls -la ~/.local/bin ~/Library/LaunchAgents /usr/local/bin /opt/homebrew/bin 2>/dev/null
```

If the installer just provides dependencies, translate them into a project `flake.nix` or `home.packages`. If it installs a daemon/LaunchAgent, consider making a Home Manager/nix-darwin module instead of leaving it unmanaged.

### Classifying new tools

Ask: where should this live?

- **Global CLI I use every week** → Nix/Home Manager package.
- **GUI app** → Homebrew cask in Nix.
- **Project-only dependency** → project `flake.nix` + `.envrc`.
- **Secret/API key** → `secrets/env-secrets.age`.
- **Daemon/background service** → declare in nix-darwin/Home Manager launchd.
- **Experiment I may delete tomorrow** → project dev shell or throwaway directory.

## Adding CLI tools

Prefer Nix packages.

Shared user tools usually go in `home/common.nix`:

```nix
home.packages = with pkgs; [
  ripgrep
  fd
  jq
  my-new-tool
];
```

Dev tools usually go in `home/dev.nix`:

```nix
home.packages = with pkgs; [
  python312
  uv
  ruff
  nil
  nixfmt
  my-dev-tool
];
```

Editor/LSP tools go in `home/editor.nix`.

Check whether a package exists in nixpkgs:

```sh
nix search nixpkgs my-tool
```

After editing:

```sh
nixfmt home/dev.nix
darwin-rebuild build --flake ~/.config/nix-darwin
rebuild
```

## Adding Homebrew casks and formulae

Homebrew is managed by nix-homebrew. Important current setting in `modules/homebrew.nix`:

```nix
homebrew.onActivation.cleanup = "zap";
```

That means Homebrew items not declared in Nix can be removed during activation. Declare what you want to keep.

### Shared GUI app

Edit `modules/homebrew.nix`:

```nix
homebrew.casks = [
  "ghostty"
  "1password"
  "new-shared-app"
];
```

### Host-specific GUI app

Edit `hosts/tanngrisnir.nix`:

```nix
homebrew.casks = [
  "vlc"
  "todoist-app"
  "new-personal-app"
];
```

### Formulae

Use Homebrew formulae sparingly, only when a CLI is not viable from Nix.

Edit `modules/homebrew.nix`:

```nix
homebrew.brews = [
  "some-formula"
];
```

Before adding casks, check the canonical token:

```sh
brew info --cask todoist
brew info --cask ollama
```

Some aliases resolve but the installed canonical token differs, e.g. `todoist-app` and `ollama-app`. Prefer canonical names in this repo.

After editing:

```sh
nixfmt modules/homebrew.nix hosts/tanngrisnir.nix
darwin-rebuild build --flake ~/.config/nix-darwin
rebuild
```

## Updating environment variables

### Non-secret env vars

For normal variables safe to commit, use Home Manager.

In `home/shell.nix`:

```nix
programs.zsh.sessionVariables = {
  EDITOR = "nvim";
  SOME_FLAG = "true";
};
```

Or in another Home Manager module:

```nix
home.sessionVariables = {
  FOO = "bar";
};
```

Then:

```sh
nixfmt home/shell.nix
darwin-rebuild build --flake ~/.config/nix-darwin
rebuild
```

Open a new terminal and verify:

```sh
echo "$SOME_FLAG"
```

### Secret env vars

Use agenix:

```sh
cd ~/.config/nix-darwin/secrets
age-edit env-secrets.age
```

Add shell exports:

```sh
export OPENROUTER_API_KEY='...'
export ANTHROPIC_API_KEY='...'
export HF_TOKEN='...'
```

Do not paste or print these values in chats, logs, or docs.

After saving, `agenix` may print a message like:

```text
Files .../env-secrets.age.before and .../env-secrets.age differ
```

That is normal. It means the plaintext changed and was re-encrypted.

Validate without printing secrets:

```sh
cd ~/.config/nix-darwin/secrets
age -d -i ~/.ssh/id_ed25519_github env-secrets.age >/dev/null && echo ok
```

Then stage the encrypted file:

```sh
cd ~/.config/nix-darwin
git add secrets/env-secrets.age
```

After activation, `/run/agenix/env-secrets` is plaintext on disk and sourced by zsh from `home/shell.nix`:

```sh
if [ -f /run/agenix/env-secrets ]; then
  source /run/agenix/env-secrets
fi
```

Verify a variable is loaded without printing it:

```sh
[ -n "${OPENROUTER_API_KEY:-}" ] && echo "OPENROUTER_API_KEY loaded"
```

## Storing and retrieving secrets

### How this repo's agenix setup works

- `secrets/secrets.nix` contains public recipients only. Safe to commit.
- `secrets/env-secrets.age` contains encrypted secrets. Safe to commit.
- At activation, agenix decrypts to `/run/agenix/env-secrets` using `/etc/ssh/ssh_host_ed25519_key`.
- The 1Password recovery/editing key is stored at:

```sh
op://Personal/agenix-key/password
```

- `age-edit` reads that key into a temporary file, edits the secret, then deletes the temp key.

### Edit existing env secrets

```sh
cd ~/.config/nix-darwin/secrets
age-edit env-secrets.age
```

### Read a secret locally without printing it

```sh
op read op://Personal/agenix-key/password >/dev/null && echo "1Password age key readable"
```

### Validate encrypted file decrypts

```sh
cd ~/.config/nix-darwin/secrets
age -d -i ~/.ssh/id_ed25519_github env-secrets.age >/dev/null && echo "decrypt ok"
```

### Rekey secrets after changing recipients

If you add a new host public key or recovery public key to `secrets/secrets.nix`:

```sh
cd ~/.config/nix-darwin/secrets
agenix -r -i ~/.ssh/id_ed25519_github
```

Then stage the changed `.age` files:

```sh
git add secrets/secrets.nix secrets/*.age
```

### Add a new secret file

1. Add a rule in `secrets/secrets.nix`:

```nix
"new-secret.age".publicKeys = [
  tanngrisnir
  alex-github
  recovery
];
```

2. Create/edit it:

```sh
cd ~/.config/nix-darwin/secrets
age-edit new-secret.age
```

3. Declare it in `hosts/common.nix` or a host module:

```nix
age.secrets.new-secret = {
  file = ../secrets/new-secret.age;
  owner = user;
  mode = "0400";
};
```

4. Build:

```sh
cd ~/.config/nix-darwin
nixfmt hosts/common.nix secrets/secrets.nix
git add secrets/new-secret.age secrets/secrets.nix hosts/common.nix
darwin-rebuild build --flake ~/.config/nix-darwin
```

## Hermes Agent workflow

Hermes is managed declaratively in `home/hermes.nix`.

Important split:

- Package/executable/LaunchAgent: Nix-managed.
- Runtime state/config/memory/sessions/skills/auth: still under `~/.hermes`.

Do not use `hermes update` as the main update path. Update Hermes through the flake input:

```sh
cd ~/.config/nix-darwin
nix flake lock --update-input hermes-agent
darwin-rebuild build --flake ~/.config/nix-darwin
rebuild
```

Verify after activation:

```sh
which -a hermes
hermes --version
hermes config path
hermes config env-path
hermes gateway status
launchctl list | grep hermes
```

Gateway logs:

```sh
~/.hermes/logs/gateway.log
~/.hermes/logs/gateway.error.log
```

## Updating Nix inputs and the system

### Update everything

```sh
cd ~/.config/nix-darwin
nix flake update
darwin-rebuild build --flake ~/.config/nix-darwin
git diff flake.lock
rebuild
```

Or use:

```sh
nixup
```

Be aware that `nixup` updates, stages everything, and activates. For more control, do the manual sequence.

### Update one input

```sh
nix flake lock --update-input hermes-agent
nix flake lock --update-input nixpkgs
```

Then build and activate.

## Garbage collection

Clean old Nix store entries older than 30 days:

```sh
nix-gc
```

Inspect generations:

```sh
darwin-rebuild --list-generations | tail -30
home-manager generations | tail -30
```

If you need rollback safety, do not garbage-collect immediately after a major change. Wait until the system feels stable.

## Auditing drift and pollution

Use this after running installers or trying lots of tools.

### Shell files

```sh
for f in ~/.zshenv ~/.zprofile ~/.zshrc ~/.zlogin ~/.profile ~/.bash_profile ~/.bashrc; do
  if [ -e "$f" ] || [ -L "$f" ]; then
    echo "-- $f --"
    ls -la "$f"
    readlink "$f" 2>/dev/null || true
  fi
done
```

Watch for manual `export PATH=...`, `brew shellenv`, conda, cargo, pipx, or installer blocks.

### Homebrew

```sh
brew list --formula
brew leaves
brew list --cask
brew services list
brew bundle dump --file=- --describe --force
```

Compare to `modules/homebrew.nix` and host files.

### Global language package managers

```sh
npm list -g --depth=0
pipx list
cargo install --list
gem list --user-install
go env GOPATH GOBIN
```

Durable global tools should move to Nix. Project-only tools should move to project flakes.

### LaunchAgents and global binaries

```sh
ls -la ~/Library/LaunchAgents /Library/LaunchAgents /Library/LaunchDaemons 2>/dev/null
ls -la ~/.local/bin /usr/local/bin /opt/homebrew/bin 2>/dev/null | head -200
launchctl list | grep -Ei 'hermes|ollama|steam|claude|codex|zeroclaw'
```

GUI app preferences and caches in `~/Library` are normal. Focus on things that affect PATH, global binaries, background services, and shell startup.

## Commit checklist

Before committing:

```sh
cd ~/.config/nix-darwin
git status
nixfmt $(git diff --name-only -- '*.nix')
darwin-rebuild build --flake ~/.config/nix-darwin
git diff
git diff --cached
git add -A
git commit -m "your message"
```

Never commit plaintext secret files. Safe to commit:

- `*.nix`
- `flake.lock`
- `secrets/*.age`
- documentation

Do not commit:

- decrypted secret temp files
- `.env` files with real secrets
- private SSH keys
- raw API keys/tokens

## Common troubleshooting

### `age-edit` reads the wrong 1Password vault

Check active wrapper:

```sh
grep -n 'op://.*agenix-key' ~/.local/bin/age-edit
readlink ~/.local/bin/age-edit
```

The correct path for this setup is:

```sh
op://Personal/agenix-key/password
```

If the repo is fixed but the active wrapper is old, activate:

```sh
rebuild
```

Or use the one-off direct path:

```sh
cd ~/.config/nix-darwin/secrets
TMPKEY=$(mktemp)
chmod 600 "$TMPKEY"
trap 'rm -f "$TMPKEY"' EXIT
op read "op://Personal/agenix-key/password" > "$TMPKEY"
agenix -e env-secrets.age -i "$TMPKEY"
```

### `age-keygen -o "$tmp"` says file exists

`mktemp` creates the file and `age-keygen -o` refuses to overwrite it. Use a temp directory:

```sh
tmpdir=$(mktemp -d)
key="$tmpdir/agenix-key.txt"
age-keygen -o "$key"
age-keygen -y "$key"
rm -rf "$tmpdir"
```

### New files are ignored by flake builds

Flakes in a Git worktree ignore untracked files. Stage new files before build:

```sh
git add path/to/new-file
darwin-rebuild build --flake ~/.config/nix-darwin
```

### `sudo: a password is required`

This agent cannot enter your sudo password. Run activation yourself:

```sh
sudo darwin-rebuild switch --flake ~/.config/nix-darwin
```

### A command exists but comes from Homebrew instead of Nix

Check:

```sh
which -a command-name
```

Avoid putting `eval "$(/opt/homebrew/bin/brew shellenv)"` in `.zprofile`; it can put Homebrew before Nix in PATH. This repo manages `.zprofile` declaratively and keeps it intentionally minimal.

## Fresh-machine recovery notes

On a new Mac:

1. Install/bootstrap Nix and this repo.
2. Make sure the host SSH public key is added to `secrets/secrets.nix`.
3. Rekey secrets so the new host can decrypt them.
4. Activate nix-darwin.
5. Sign in to 1Password and enable CLI integration.
6. Verify agenix and env secrets:

```sh
ls -l /run/agenix/env-secrets
op read op://Personal/agenix-key/password >/dev/null && echo "1Password key readable"
```

Remember: activation decryption should depend on the host SSH key, not 1Password. 1Password is for portable human editing and recovery.
