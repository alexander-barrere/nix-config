{ pkgs, ... }:

{
  networking.hostName = "tanngrisnir";
  networking.computerName = "Thor's MacBook Pro";

  # Personal-only Homebrew casks
  homebrew.casks = [
    # Media & Entertainment
    "vlc"
    "discord"

    # Personal Productivity
    "notion"
    "todoist-app"
    "rectangle" # Window snapping

    # Optional: Gaming (uncomment if wanted)
    "steam"
  ];
}
