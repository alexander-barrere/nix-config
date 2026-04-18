{ hostname, ... }:

let
  emailMap = {
    "personal-mbp" = "alexander-barrere@users.noreply.github.com";
    "work-mbp" = "alexander-barrere@users.noreply.github.com";
  };
in
{
  programs.git = {
    enable = true;

    # SSH signing disabled - add your own key later
    # signing = {
    #   key = "ssh-ed25519 YOUR_SSH_KEY_HERE";
    #   signByDefault = true;
    # };

    settings = {
      user = {
        name = "Alexander Barrere";
        email = emailMap.${hostname} or "alexander-barrere@users.noreply.github.com";
      };
      gpg.format = "ssh";
      "gpg.ssh".allowedSignersFile = "~/.config/git/allowed_signers";
      "gpg.ssh".program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
      rerere.enabled = true;
      core.editor = "nvim";
    };

    ignores = [
      ".DS_Store"
      ".direnv"
      "result"
      "result-*"
    ];
  };

  # SSH signing disabled - add your own key later
  # xdg.configFile."git/allowed_signers".text = ''
  #   alexander-barrere@users.noreply.github.com ssh-ed25519 YOUR_SSH_KEY_HERE
  # '';

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        extraOptions = {
          IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
          AddKeysToAgent = "yes";
          UseKeychain = "yes";
        };
      };
    };
  };
}
