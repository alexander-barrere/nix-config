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

  # Agenix secrets are encrypted in ./secrets/*.age and safe to commit.
  # Decryption at activation uses the host SSH key, so rebuilds do not depend on
  # 1Password being available before the system is built.
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  age.secrets.env-secrets = {
    file = ../secrets/env-secrets.age;
    owner = user;
    mode = "0400";
  };

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
