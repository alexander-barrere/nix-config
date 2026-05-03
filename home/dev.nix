{ pkgs, fenixPkgs, ... }:

let
  rustToolchain = fenixPkgs.stable.withComponents [
    "cargo"
    "clippy"
    "rust-analyzer"
    "rust-src"
    "rust-std"
    "rustc"
    "rustfmt"
  ];
in
{
  home.packages = with pkgs; [
    # Rust — complete toolchain from fenix
    rustToolchain

    # Python
    python312
    uv
    ruff
    ty

    # Local AI / media workflow support
    git-lfs
    aria2
    ffmpeg

    # Nix development
    nil
    nixfmt
  ];
}
