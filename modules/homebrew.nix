{ ... }:

{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      cleanup = "zap"; # Remove anything not declared here
      upgrade = true;
    };

    # GUI apps shared across all machines
    casks = [
      "ghostty"
      "discord"
      "1password"
      "1password-cli"
      "hammerspoon"
      "claude" # Claude desktop app
      "claude-code" # Claude Code CLI (auto-updates via cask)
      "font-meslo-lg-nerd-font"

      # Productivity & Utilities
      "maccy" # Clipboard manager
      "obsidian" # Note-taking
      "raycast" # Spotlight alternative
      "arc" # Browser
      "cleanmymac" # System maintenance

      # Development
      "cursor" # AI code editor
      "codex"
      "aionui"
      "ollama-app" # Local AI
    ];

    # CLI tools from Homebrew (only if not in nixpkgs)
    brews = [
    ];

    # Mac App Store apps (requires mas CLI and App Store sign-in)
    masApps = {
      # "Xcode" = 497799835;
    };
  };
}
