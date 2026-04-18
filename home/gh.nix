{ lib, ... }:

{
  home.activation.ghAuth = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/.config/gh

    # Write config (not managed by HM symlink so gh can migrate it)
    cat > ~/.config/gh/config.yml << 'CFGEOF'
git_protocol: ssh
editor: nvim
prompt: enabled
pager: delta
CFGEOF

    # GitHub token disabled - set up manually with: gh auth login
    # if [ -f /run/agenix/github-token ]; then
    #   TOKEN=$(cat /run/agenix/github-token)
    #   (
    #     umask 077
    #     cat > ~/.config/gh/hosts.yml << EOF
    # github.com:
    #     oauth_token: $TOKEN
    #     user: alexander-barrere
    #     git_protocol: ssh
    # EOF
    #   )
    # fi
  '';
}
