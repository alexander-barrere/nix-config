let
  # Public keys for agenix encryption
  # Add your recovery age key and SSH keys here when setting up secrets
  # recovery = "age1...your-recovery-key...";
  # alexander-barrere = "ssh-ed25519 ...your-ssh-key...";
  # your-hostname = "ssh-ed25519 ...host-ssh-key...";
in
{
  # Uncomment and update when you set up secrets
  # "github-token.age".publicKeys = [ recovery alexander-barrere your-hostname ];
  # "env-secrets.age".publicKeys = [ recovery alexander-barrere your-hostname ];
}
