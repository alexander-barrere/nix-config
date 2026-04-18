{ pkgs, user, ... }:

{
  imports = [
    ../modules/homebrew.nix
    ../modules/defaults.nix
    ../modules/system.nix
  ];

  # Determinate Nix manages the Nix installation
  nix.enable = false;

  # System-wide packages
  environment.systemPackages = with pkgs; [
    vim
    curl
    wget
    git
  ];

  # User account
  users.users.${user} = {
    shell = pkgs.zsh;
    home = "/Users/${user}";
  };

  system.primaryUser = user;

  # Secrets disabled - set up agenix later if needed
  # age.secrets.github-token = {
  #   file = ../secrets/github-token.age;
  #   owner = user;
  # };

  # age.secrets.env-secrets = {
  #   file = ../secrets/env-secrets.age;
  #   owner = user;
  # };

  # Enable Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Required for backwards compatibility
  system.stateVersion = 5;
  system.activationScripts.postActivation.text = ''
    HM_APPS="/Users/${user}/Applications/Home Manager Apps"
    if [ -d "$HM_APPS" ]; then
      for app in "$HM_APPS"/*.app; do
        if [ -e "$app" ]; then
          APP_NAME=$(basename "$app")
          REAL_APP=$(readlink -f "$app")
          rm -rf "/Applications/$APP_NAME"
          ditto "$REAL_APP" "/Applications/$APP_NAME"
        fi
      done
    fi
  '';
}
