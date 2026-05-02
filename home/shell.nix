{ pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
    };

    shellAliases = {
      ls = "eza";
      ll = "eza -la";
      lt = "eza --tree";
      cat = "bat";
      terraform = "tofu";
      tf = "tofu";
      g = "git";
      gaa = "git add -A";
      gs = "git status";
      gd = "git diff";
      gco = "git checkout";
      nixd = "cd ~/.config/nix-darwin";
      nixup = "nixd && nix flake update && gaa && rebuild";
      rebuild = "sudo darwin-rebuild switch --flake ~/.config/nix-darwin";
      rollback = "sudo darwin-rebuild switch --rollback";
      nix-gc = "nix-collect-garbage --delete-older-than 30d";
      direnv-reset = "chmod -R u+w .direnv && rm -rf .direnv && direnv allow";
      rr = "open -a RustRover .";
    };

    initContent = lib.mkMerge [
      (lib.mkOrder 550 ''
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
      '')

      ''
        # Vi mode
        bindkey -v

        # Terminal/Home-End portability. On macOS, Fn+Left/Fn+Right are Home/End,
        # but different terminal emulators send different escape sequences. Bind
        # the common variants so they move to beginning/end of the command line
        # instead of inserting literal escape text.
        bindkey '^[[H' beginning-of-line
        bindkey '^[OH' beginning-of-line
        bindkey '^[[1~' beginning-of-line
        bindkey '^[[F' end-of-line
        bindkey '^[OF' end-of-line
        bindkey '^[[4~' end-of-line

        # Prefix-aware history search: type `curl`, then Up/Down cycles through
        # history entries beginning with `curl` instead of all history entries.
        autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
        zle -N up-line-or-beginning-search
        zle -N down-line-or-beginning-search
        bindkey '^[[A' up-line-or-beginning-search
        bindkey '^[OA' up-line-or-beginning-search
        bindkey '^[[B' down-line-or-beginning-search
        bindkey '^[OB' down-line-or-beginning-search

        # Alt+Left/Right to jump words
        bindkey '\eb' backward-word
        bindkey '\ef' forward-word

        # Alt+Backspace to delete word segment
        bindkey '\e^?' backward-kill-word

        # Better full-text history search
        bindkey '^R' history-incremental-search-backward

        # Custom functions
        mkcd() {
          mkdir -p "$1" && cd "$1"
        }

        # Editor
        export EDITOR="nvim"

        # Source secrets if they exist
        if [ -f /run/agenix/env-secrets ]; then
          source /run/agenix/env-secrets
        fi
      ''
    ];

    sessionVariables = {
      LANG = "en_US.UTF-8";
      LESS = "-R";
      WORDCHARS = "";
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      command_timeout = 1000;

      format = ''
        [](blue)[ $directory](bg:blue fg:black)[](fg:blue bg:green)[$git_branch$git_status](bg:green fg:black)[](fg:green) $python$rust$nodejs$terraform$nix_shell$custom$cmd_duration$fill$time
        $character
      '';

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
        vimcmd_symbol = "[❮](bold cyan)";
      };

      fill.symbol = " ";

      time = {
        disabled = false;
        format = "[$time]($style)";
        time_format = "%H:%M";
        style = "dimmed white";
      };

      cmd_duration = {
        min_time = 3000;
        format = "[took $duration]($style) ";
        style = "bold yellow";
      };

      directory = {
        format = " $path ";
        truncation_length = 0;
        truncate_to_repo = false;
        fish_style_pwd_dir_length = 0;
        home_symbol = "~";
      };

      git_branch = {
        symbol = "󰘬 ";
        format = " $symbol$branch ";
      };

      git_status = {
        format = "($all_status$ahead_behind)";
        conflicted = "= ";
        ahead = "⇡ ";
        behind = "⇣ ";
        diverged = "⇕ ";
        untracked = "? ";
        stashed = "* ";
        modified = "! ";
        staged = "+ ";
        renamed = "» ";
        deleted = "✘ ";
      };

      git_state = {
        format = "[\($state( $progress_current/$progress_total)\)]($style) ";
        style = "bold yellow";
      };

      python = {
        symbol = "󰌠 ";
        format = "[$symbol$version]($style) ";
        style = "bold green";
      };

      custom.virtualenv = {
        command = "basename $(dirname $VIRTUAL_ENV)";
        when = "test -n \"$VIRTUAL_ENV\"";
        format = "[(\\($output\\))]($style) ";
        style = "bold green";
      };

      rust = {
        symbol = "󱘗 ";
        format = "[$symbol$version]($style) ";
        style = "bold red";
      };

      nix_shell = {
        symbol = "󱄅 ";
        format = "via [$symbol( \\($name\\))]($style) ";
        style = "bold blue";
      };

      nodejs = {
        symbol = "󰎙 ";
        format = "[$symbol$version]($style) ";
        style = "bold green";
      };

      terraform = {
        symbol = "󱁢 ";
        format = "[$symbol$version]($style) ";
        style = "bold purple";
      };
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}
