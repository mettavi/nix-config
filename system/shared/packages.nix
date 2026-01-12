{
  config,
  pkgs,
  ...
}:
let
  # this will point to a stable nixpkgs input rather than the default one
  # use "nixpkgs_name.package_name" to install a non-default package
  # nixpkgs-24_11 = inputs.nixpkgs-24_11.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  # nixpkgs-24_05 = inputs.nixpkgs-24_05.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  # place custom packages in one directory for ease of reference
  # each individual package is further defined in ./pkgs/default.nx
  # mypkgs = (pkgs.callPackage ./pkgs { });

  # OVERRIDES
  # get bfg to use the jdk already installed in environment.systemPackages instead of openjdk
  # bfg-repo-cleaner_zulu = pkgs.bfg-repo-cleaner.override { jre = pkgs.zulu; };
in
{

  imports = [
    ./vim.nix
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.meslo-lg
  ];

  # install standard packages
  environment.systemPackages = with pkgs; [
    # CLI PACKAGES
    age # Modern encryption tool with small explicit keys
    asciiquarium-transparent # Aquarium/sea animation in ASCII art
    # atomicparsley
    bats
    # bento4
    cachix
    cargo
    chafa
    # cmake
    cmatrix
    cowsay
    gitleaks
    gyb # a command line tool for backing up your Gmail messages
    nix-fast-build # speed-up your evaluation and building process
    nix-init # Generate Nix packages from URLs
    nix-update # Swiss-knife for updating nix packages
    node2nix # Generate Nix expressions to build NPM packages
    nurl # generate Nix fetcher calls from repository URLs
    ocrmypdf
    # pipx
    # pnpm
    # poppler
    # python-launcher
    ruby
    rustc
    shellcheck
    sops # Simple and flexible tool for managing secrets
    ssh-to-age # convert ssh keys in ed25519 format to age keys
    # texinfo # to read info files
    tldr
    tree
    wget
    zsh-completions
    zsh-powerlevel10k

    # "PINNED" APPS

    # GUI APPS
    # anki # this is currently marked as broken in all nix branches (as at 2025/01/01)
    # bitwarden-desktop
    # brave
    # dbeaver-bin
    # djview
    # google-chrome
    # goldendict-ng is currently only available for linux
    # vlc-bin-universal
  ];
}
