{ ... }:

{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";         # Remove anything not declared here
      upgrade = true;
    };

    # GUI apps shared across all machines
    casks = [
      "ghostty"
      "1password"
      "1password-cli"
      "hammerspoon"
      "claude"                 # Claude desktop app
      "claude-code"            # Claude Code CLI (auto-updates via cask)

      # Productivity & Utilities
      "maccy"                  # Clipboard manager
      "obsidian"               # Note-taking
      "raycast"                # Spotlight alternative
      "arc"                    # Browser
      "cleanmymac"             # System maintenance
      "bartender-4"            # Menu bar organization

      # Development
      "warp"                   # Modern terminal
      "cursor"                 # AI code editor
      "figma"                  # Design tool
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
