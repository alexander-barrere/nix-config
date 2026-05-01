{
  pkgs,
  hostname,
  agenixPkgs,
  ...
}:

{
  imports = [
    ./shell.nix
    ./git.nix
    ./editor.nix
    ./dev.nix
    ./scripts.nix
    ./firefox.nix
    ./fastfetch.nix
    ./claude-code.nix
    ./gh.nix
  ];

  home.stateVersion = "24.05";

  home.packages =
    (with pkgs; [
      ripgrep
      fastfetch
      fd
      gh
      jq
      bat
      eza
      fzf
      delta
      htop
      tmux
      tokei
      tree
      wget
      curl
      age
    ])
    ++ [
      agenixPkgs.default
    ];

  home.sessionPath = [ "$HOME/.local/bin" ];

  # Keep login-shell startup declarative and intentionally minimal.
  # Do not run `brew shellenv` here: nix-homebrew exposes brew through managed
  # system paths, and putting Homebrew first can shadow Nix-provided CLI tools.
  home.file.".zprofile".text = ''
    # Managed by Home Manager via ~/.config/nix-darwin/home/common.nix
    # Login-shell customizations belong in nix-darwin/Home Manager, not here.
  '';

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "ansi";
      pager = "never";
    };
  };

  # Ghostty config (binary installed via Homebrew cask)
  xdg.configFile."ghostty/config".text = ''
    # ============================================================================
    # GHOSTTY CONFIGURATION FOR MACOS
    # ============================================================================
    # This configuration uses Ghostty's excellent default keybindings.
    # We only define appearance settings and a few custom overrides here.
    #
    # KEY TERMINOLOGY (for reference):
    # - "super" = Command key (⌘)
    # - "ctrl" = Control key (⌃)
    # - "alt" = Option/Alt key (⌥)
    # - "shift" = Shift key (⇧)
    # ============================================================================

    # ============================================================================
    # APPEARANCE & VISUAL SETTINGS
    # ============================================================================

    # Font Configuration
    # MesloLGS NF provides excellent support for Powerline and Nerd Font icons
    font-family = MesloLGS NF
    font-size = 12
    font-thicken = true

    # Window Aesthetics
    # Creates a modern, translucent appearance with blur effect
    background-opacity = 0.85
    background-blur-radius = 70
    window-padding-x = 12
    window-padding-y = 12

    # macOS-specific Window Style
    # Hides the title bar for a cleaner, more immersive terminal experience

    # Color Theme
    theme = Synthwave Everything

    # ============================================================================
    # CUSTOM KEYBINDINGS
    # ============================================================================
    # Override defaults to match standard macOS terminal behavior


    # ============================================================================
    # DEFAULT KEYBINDINGS REFERENCE
    # ============================================================================
    # Ghostty comes with excellent default keybindings for macOS.
    # Here's what's available out of the box:
    #
    # TAB MANAGEMENT:
    # ⌘+T                  Create new tab (overridden above)
    # ⌘+W                  Close current tab
    # ⌘+Shift+[            Previous tab
    # ⌘+Shift+]            Next tab
    # ⌘+1 through ⌘+9      Jump to tab 1-9
    # ⌘+0                  Jump to last tab
    #
    # WINDOW MANAGEMENT:
    # ⌘+N                  New window
    # ⌘+Shift+N            New window (alternative)
    #
    # SPLIT/PANE MANAGEMENT:
    # ⌘+D                  New vertical split (right)
    # ⌘+Shift+D            New horizontal split (down)
    # ⌘+[                  Previous split
    # ⌘+]                  Next split
    # ⌘+Alt+Arrow          Resize splits (10px increments)
    # ⌘+Shift+Enter        Toggle split zoom/fullscreen
    # ⌘+Shift+E            Equalize all splits
    #
    # TERMINAL UTILITIES:
    # ⌘+K                  Clear screen
    # ⌘+Plus               Increase font size
    # ⌘+Minus              Decrease font size
    # ⌘+0                  Reset font size
    # ⌘+C                  Copy (when text selected)
    # ⌘+V                  Paste
    #
    # ADVANCED FEATURES:
    # ⌘+Comma              Open configuration
    # ⌘+Shift+Comma        Reload configuration
    # ⌘+Alt+I              Toggle inspector (debugging)
    # ⌘+Ctrl+F             Toggle fullscreen
    #
    # SEARCH:
    # ⌘+F                  Open search
    # ⌘+G                  Find next
    # ⌘+Shift+G            Find previous
    #
    # For the complete list of available actions and default keybindings, see:
    # https://ghostty.org/docs/config/reference
    # ============================================================================
    # ============================================================================
    # WORKFLOW RECOMMENDATIONS
    # ============================================================================
    # 
    # SUGGESTED USAGE PATTERNS:
    # 1. Use Ghostty tabs (⌘+T) for completely separate projects/contexts
    #    - Each tab can run its own shell session or tmux session
    #    - Switch between tabs with ⌘+1-9 for quick access
    #
    # 2. Use Ghostty splits (⌘+D, ⌘+Shift+D) for side-by-side work
    #    - Perfect for comparing outputs, monitoring logs, or running tests
    #    - Navigate splits with ⌘+[ and ⌘+]
    #    - Resize with ⌘+Alt+Arrow keys
    #    - Zoom a split with ⌘+Shift+Enter
    #
    # 3. Use tmux for persistent sessions and complex workflows
    #    - Start tmux in a Ghostty tab: just type tmux or tmux attach
    #    - tmux sessions survive Ghostty restarts
    #    - Great for remote work, long-running processes
    #
    # COMBINING GHOSTTY + TMUX:
    # - Ghostty provides the modern, native macOS terminal experience
    # - tmux adds session persistence and advanced multiplexing
    # - Use Ghostty's splits for temporary layouts
    # - Use tmux sessions for persistent workspaces
    # - You get the best of both worlds!
    #
    # CUSTOMIZATION:
    # To override any default keybinding, simply add a keybind line above.
    # For example, to change the split behavior:
    #   keybind = super+d=new_split:down
    #
    # To disable a default keybinding:
    #   keybind = super+d=unbind
    # ============================================================================
  '';

  # Hammerspoon config (binary installed via Homebrew cask)
  home.file.".hammerspoon/init.lua".source = ./hammerspoon/init.lua;
}
