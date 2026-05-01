let
  # Public recipients for agenix encryption.
  # These are safe to commit; only matching private keys can decrypt the .age files.

  # Host key used by nix-darwin/agenix during activation. This avoids depending on
  # 1Password at build/switch time, which solves the bootstrap chicken-and-egg.
  tanngrisnir = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFYYOQcXrJ7LS/dRBjht4/IQnkBW0/y8HDhjjZsmJC8m";

  # User editing key. Keep this private key in 1Password/SSH agent for portable edits.
  alex-github = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBwk8D1AogLNwXCaWeS7w9NuEg19ARvDxZD0D3Ojrs3K";

  # Portable recovery/editing key stored in 1Password:
  # op://Personal/agenix-key/password
  recovery = "age1e48ux00x2dm4lpdkarax939v809whx3yux9vlc62n95fnw7pxe9qgr7wzk";
in
{
  "env-secrets.age".publicKeys = [
    tanngrisnir
    alex-github
    recovery
  ];
}
