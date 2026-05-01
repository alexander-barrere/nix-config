{ hermesAgentPackage, user, ... }:

let
  homeDir = "/Users/${user}";
  hermesHome = "${homeDir}/.hermes";
  hermesBin = "${hermesAgentPackage}/bin/hermes";
  managedPath = builtins.concatStringsSep ":" [
    "${hermesAgentPackage}/bin"
    "${homeDir}/.local/bin"
    "/etc/profiles/per-user/${user}/bin"
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/usr/local/bin"
  ];
in
{
  home.packages = [ hermesAgentPackage ];

  # Keep the historical ~/.local/bin entrypoint, but make it point at the
  # immutable Nix package instead of the bootstrapper-created virtualenv.
  home.file.".local/bin/hermes" = {
    source = "${hermesAgentPackage}/bin/hermes";
    executable = true;
  };

  home.file.".local/bin/hermes-agent" = {
    source = "${hermesAgentPackage}/bin/hermes-agent";
    executable = true;
  };

  home.file.".local/bin/hermes-acp" = {
    source = "${hermesAgentPackage}/bin/hermes-acp";
    executable = true;
  };

  # Declarative replacement for `hermes gateway install`.
  # Runtime state, sessions, memories, skills, auth, and secrets stay in
  # HERMES_HOME so they remain mutable user data and are not committed to Nix.
  launchd.agents."ai.hermes.gateway" = {
    enable = true;
    config = {
      Label = "ai.hermes.gateway";
      ProgramArguments = [
        hermesBin
        "gateway"
        "run"
        "--replace"
      ];
      WorkingDirectory = homeDir;
      EnvironmentVariables = {
        HERMES_HOME = hermesHome;
        PATH = managedPath;
      };
      RunAtLoad = true;
      KeepAlive = {
        SuccessfulExit = false;
      };
      StandardOutPath = "${hermesHome}/logs/gateway.log";
      StandardErrorPath = "${hermesHome}/logs/gateway.error.log";
    };
  };
}
