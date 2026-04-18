{ hostname, ... }:

let
  emailMap = {
    "tanngrisnir" = "alexander-barrere@users.noreply.github.com";
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
          SetEnv = "TERM=xterm-256color";
        };
      };

      "github.com" = {
        identityFile = "~/.ssh/id_ed25519_github";
        identitiesOnly = true;
      };

      "68.65.120.251" = {
        port = 21098;
        user = "exeldith";
        identityFile = "~/.ssh/exelan.io.key";
      };

      "46.202.178.46" = {
        port = 22;
        user = "ai";
        identityFile = "~/.ssh/ai_hostinger_ed25519";
      };

      "129.121.77.19" = {
        port = 2222;
        user = "starfires-admin";
        identityFile = "~/.ssh/id_ed25519";
      };

      "66.29.146.54" = {
        port = 21098;
        user = "exelfvsy";
        identityFile = "~/.ssh/id_rsa_namecheap";
      };

      "50.87.220.158" = {
        port = 2222;
        user = "starfja8";
        identityFile = "~/.ssh/starfires.key";
        identitiesOnly = true;
      };

      "172.232.185.22" = {
        port = 22;
        user = "webdev";
        identityFile = "~/.ssh/starfires.io";
      };

      "www.starfires.io" = {
        port = 22;
        user = "webdev";
        identityFile = "~/.ssh/starfires.io";
      };

      "gitea" = {
        hostname = "192.168.121.120";
        port = 2222;
        identityFile = "~/.ssh/gitea.key";
      };
    };
  };
}
