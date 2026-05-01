{ ... }:

{
  home.file.".local/bin/age-edit" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      FILE="''${1:?Usage: age-edit <secret-file.age>}"
      SECRETS_DIR="$HOME/.config/nix-darwin/secrets"

      # Pull the portable recovery/editing age identity from 1Password.
      # The system itself decrypts at activation with /etc/ssh/ssh_host_ed25519_key,
      # so 1Password is only needed when humans edit/rekey secrets.
      if command -v op >/dev/null 2>&1; then
        OP_BIN="$(command -v op)"
      elif [ -x /opt/homebrew/bin/op ]; then
        OP_BIN="/opt/homebrew/bin/op"
      else
        echo "Error: 1Password CLI 'op' not found. Install/activate the 1password-cli cask first." >&2
        exit 1
      fi

      TMPKEY=$(mktemp)
      chmod 600 "$TMPKEY"
      trap 'rm -f "$TMPKEY"' EXIT
      if ! "$OP_BIN" read "op://Personal/agenix-key/password" > "$TMPKEY"; then
        echo "Error: could not read op://Personal/agenix-key/password." >&2
        echo "Sign in with 'op account add' / 'op signin', then create the agenix-key item." >&2
        exit 1
      fi

      cd "$SECRETS_DIR"
      agenix -e "$FILE" -i "$TMPKEY"
    '';
  };

  # Python project scaffolding
  home.file.".local/bin/mkpy" = {
    executable = true;
    text = ''
            #!/usr/bin/env bash
            set -euo pipefail

            PROJECT_NAME="''${1:?Usage: mkpy <project-name>}"
            if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
              echo "Error: project name must start with a letter and contain only letters, digits, dashes, and underscores" >&2
              exit 1
            fi
            FLAKE_REF="path:$HOME/.config/nix-darwin"

            if [ -d "$PROJECT_NAME" ]; then
              echo "Error: $PROJECT_NAME already exists" >&2
              exit 1
            fi

            mkdir -p "$PROJECT_NAME"
            cd "$PROJECT_NAME"

            nix flake init -t "$FLAKE_REF#python"
            echo "use flake" > .envrc
            sed -i "" "s|^name = .*|name = \"$PROJECT_NAME\"|" pyproject.toml

            cat > CLAUDE.md << 'CLAUDEEOF'
      # Project Guidelines

      ## Language & Tooling
      - Python 3.14+ with uv for package management
      - Ruff for linting and formatting
      - Type hints required on all function signatures
      - Docstrings on all public functions (Google style)

      ## Code Style
      - Follow PEP 8
      - Use pathlib over os.path
      - Prefer dataclasses or Pydantic models over raw dicts
      - Use logging module, not print() for diagnostics
      - Use context managers for resource handling

      ## Testing
      - pytest for all tests
      - Tests go in tests/ directory, mirroring src/ structure
      - Name test files test_<module>.py
      - Aim for meaningful tests, not coverage metrics

      ## Project Structure
      - Source code in src/<project_name>/
      - Entry point in src/<project_name>/__init__.py or __main__.py
      - Configuration in pyproject.toml (no setup.py)

      ## Git
      - Conventional commits (feat:, fix:, refactor:, docs:, test:)
      - Keep commits atomic and focused
      CLAUDEEOF

            git init
            git add -A
            direnv allow

            echo "Ready: cd $PROJECT_NAME"
    '';
  };

  # Rust project scaffolding
  home.file.".local/bin/mkrs" = {
    executable = true;
    text = ''
            #!/usr/bin/env bash
            set -euo pipefail

            PROJECT_NAME="''${1:?Usage: mkrs <project-name>}"
            if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
              echo "Error: project name must start with a letter and contain only letters, digits, dashes, and underscores" >&2
              exit 1
            fi
            FLAKE_REF="path:$HOME/.config/nix-darwin"

            if [ -d "$PROJECT_NAME" ]; then
              echo "Error: $PROJECT_NAME already exists" >&2
              exit 1
            fi

            mkdir -p "$PROJECT_NAME"
            cd "$PROJECT_NAME"

            nix flake init -t "$FLAKE_REF#rust"
            echo "use flake" > .envrc

            # Initialize cargo project inside
            nix develop --command cargo init --name "$PROJECT_NAME"

            cat > CLAUDE.md << 'CLAUDEEOF'
      # Project Guidelines

      ## Language & Tooling
      - Rust stable toolchain via fenix/Nix
      - clippy for linting (treat warnings as errors in CI)
      - rustfmt for formatting (run on save)
      - cargo test for all tests

      ## Code Style
      - Follow Rust API Guidelines (https://rust-lang.github.io/api-guidelines/)
      - Prefer returning Result over panicking
      - Use thiserror for library errors, anyhow for application errors
      - Derive Debug on all public types
      - Document public items with /// doc comments
      - Use clippy::pedantic where reasonable

      ## Error Handling
      - No unwrap() in production code (ok in tests)
      - Use ? operator for propagation
      - Custom error types for libraries
      - anyhow::Result for binaries and scripts

      ## Structure
      - src/lib.rs for library code
      - src/main.rs for binary entry point
      - Modules in src/<name>.rs or src/<name>/mod.rs
      - Integration tests in tests/
      - Benchmarks in benches/

      ## Dependencies
      - Check before adding — prefer std where possible
      - Use cargo add (will prompt for confirmation)
      - Pin major versions in Cargo.toml

      ## Git
      - Conventional commits (feat:, fix:, refactor:, docs:, test:)
      - Keep commits atomic and focused
      CLAUDEEOF

            git init
            git add -A
            direnv allow

            echo "Ready: cd $PROJECT_NAME"
    '';
  };

  # Terraform project scaffolding
  home.file.".local/bin/mktf" = {
    executable = true;
    text = ''
            #!/usr/bin/env bash
            set -euo pipefail

            PROJECT_NAME="''${1:?Usage: mktf <project-name>}"
            if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
              echo "Error: project name must start with a letter and contain only letters, digits, dashes, and underscores" >&2
              exit 1
            fi
            FLAKE_REF="path:$HOME/.config/nix-darwin"

            if [ -d "$PROJECT_NAME" ]; then
              echo "Error: $PROJECT_NAME already exists" >&2
              exit 1
            fi

            mkdir -p "$PROJECT_NAME"
            cd "$PROJECT_NAME"

            nix flake init -t "$FLAKE_REF#terraform"
            echo "use flake" > .envrc

            cat > main.tf << 'EOF'
      terraform {
        required_version = ">= 1.0"
      }
      EOF

            cat > variables.tf << 'EOF'
      # Input variables
      EOF

            cat > outputs.tf << 'EOF'
      # Output values
      EOF

            cat > CLAUDE.md << 'CLAUDEEOF'
      # Project Guidelines

      ## Tooling
      - OpenTofu (tofu) for infrastructure as code
      - terraform-ls for LSP support
      - tflint for linting

      ## Code Style
      - Use tofu fmt before committing
      - One resource per logical unit
      - Use variables for anything that changes between environments
      - Use locals for computed values and DRY expressions
      - Output all values that downstream modules or users need

      ## File Organization
      - main.tf — providers and core resources
      - variables.tf — all input variables with descriptions and types
      - outputs.tf — all output values
      - locals.tf — computed local values
      - versions.tf — required_version and required_providers
      - Split large configs into <resource_type>.tf (e.g. networking.tf, compute.tf)

      ## State & Security
      - Never commit .tfstate files
      - Never hardcode secrets — use variables or environment
      - Use remote state backends for shared infrastructure
      - Enable state locking

      ## Naming
      - Use snake_case for all resource names
      - Prefix resources with their purpose (e.g. web_sg, db_subnet)
      - Use descriptive variable names with type constraints

      ## Git
      - Conventional commits (feat:, fix:, refactor:, docs:)
      - Keep commits atomic and focused
      CLAUDEEOF

            git init
            git add -A
            direnv allow

            echo "Ready: cd $PROJECT_NAME"
    '';
  };

  # Enable MCP servers for current project
  home.file.".local/bin/mcp-init" = {
    executable = true;
    text = ''
            #!/usr/bin/env bash
            set -euo pipefail

            if [ -f .mcp.json ]; then
              echo "Error: .mcp.json already exists in this directory" >&2
              exit 1
            fi

            PROJECT_DIR="$(pwd)"

            # Auto-detect language
            LANG_ARGS=()
            if [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
              LANG_ARGS=(--language python)
            fi
            if [ -f "Cargo.toml" ]; then
              LANG_ARGS=(--language rust)
            fi
            if [ -f "main.tf" ] || ls *.tf >/dev/null 2>&1; then
              LANG_ARGS=(--language hcl)
            fi
            if [ -f "package.json" ]; then
              LANG_ARGS+=(--language typescript)
            fi

            # Fall back to explicit argument
            if [ ''${#LANG_ARGS[@]} -eq 0 ] && [ -n "''${1:-}" ]; then
              LANG_ARGS=(--language "$1")
            fi

            if [ ''${#LANG_ARGS[@]} -eq 0 ]; then
              echo "Error: Could not detect language. Pass it explicitly: mcp-init python" >&2
              exit 1
            fi

            # Initialize Serena project
            echo "Initializing Serena project..."
            uvx --from git+https://github.com/oraios/serena@v0.1.4 serena project create "''${LANG_ARGS[@]}" --index

            # Write MCP config
            cat > .mcp.json << MCPEOF
      {
        "mcpServers": {
          "context7": {
            "type": "stdio",
            "command": "npx",
            "args": ["-y", "@upstash/context7-mcp@2.1.4"],
            "env": {
              "CONTEXT7_API_KEY": "''\${CONTEXT7_API_KEY}"
            }
          },
          "serena": {
            "type": "stdio",
            "command": "uvx",
            "args": [
              "--from", "git+https://github.com/oraios/serena@v0.1.4",
              "serena", "start-mcp-server",
              "--context", "claude-code",
              "--project", "$PROJECT_DIR"
            ]
          }
        }
      }
      MCPEOF

            echo "MCP servers enabled: context7, serena"
            echo "Restart Claude Code to pick up changes"
    '';
  };

  # Universal project removal (handles .direnv permissions)
  home.file.".local/bin/rmpj" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      TARGET="''${1:?Usage: rmpj <project-dir>}"

      if [ ! -d "$TARGET" ]; then
        echo "Error: $TARGET does not exist" >&2
        exit 1
      fi

      if [ -d "$TARGET/.direnv" ]; then
        chmod -R u+w "$TARGET/.direnv"
      fi

      rm -rf "$TARGET"
      echo "Removed $TARGET"
    '';
  };
}
