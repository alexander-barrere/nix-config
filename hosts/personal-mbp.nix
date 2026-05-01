{ pkgs, ... }:

{
  networking.hostName = "personal-mbp";
  networking.computerName = "Alexander's MacBook Pro";

  # Personal-only Homebrew casks
  homebrew.casks = [
    # Media & Entertainment
    "spotify"
    "vlc"
    "discord"

    # Personal Productivity
    "notion"
    "todoist-app"
    "rectangle"

    # Optional: Gaming (uncomment if wanted)
    # "steam"
    # "league-of-legends"
  ];
}
