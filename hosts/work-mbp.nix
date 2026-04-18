# hosts/work-mbp.nix
{ pkgs, ... }:

{
  networking.hostName = "work-mbp";
  networking.computerName = "Alexander-Work";

  # Work-only Homebrew casks
  homebrew.casks = [
    "slack"
  ];

  # Work-only packages
  environment.systemPackages = with pkgs; [
    awscli2
  ];
}
