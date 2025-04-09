{
  inputs,
  pkgs,
  system,
  ...
}:
let
  # this will point to a stable nixpkgs input rather than the default one
  # use "nixpkgs_name.package_name" to install a non-default package
  # nixpkgs-24_11 = inputs.nixpkgs-24_11.legacyPackages.${system};
  # nixpkgs-24_05 = inputs.nixpkgs-24_05.legacyPackages.${system};

  nh_beta = inputs.nh.packages.${system}.nh;

  # place custom packages in one directory for ease of reference
  # each individual package is further defined in ./pkgs/default.nx
  # mypkgs = (pkgs.callPackage ./pkgs { });

in
{

  imports = [ ./restic.nix ];

  fonts.packages = with pkgs; [
    nerd-fonts.meslo-lg
  ];

  # install standard packages
  environment.systemPackages = with pkgs; [
    # PACKAGES
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
    exercism
    fastfetch
    ffmpeg
    gitleaks
    kanata # Cross-platform software keyboard remapper
    mkalias
    nix-fast-build # speed-up your evaluation and building process
    nixfmt-rfc-style
    nixd # nix language server
    nix-init # Generate Nix packages from URLs
    nix-update # Swiss-knife for updating nix packages
    node2nix # Generate Nix expressions to build NPM packages
    ntfs3g # Read-write NTFS driver for FUSE
    nurl # generate Nix fetcher calls from repository URLs
    ocrmypdf
    pinentry-tty # Passphrase entry dialog utilizing the Assuan protocol
    # pipx
    # pnpm
    # poppler
    # python-launcher
    rclone # sync files and directories to and from major cloud storage
    ruby
    rustc
    shellcheck
    sops # Simple and flexible tool for managing secrets
    stow
    # texinfo # to read info files
    tldr
    tree
    wget
    zoom-us # video conferencing application
    zsh-completions
    zsh-powerlevel10k

    # "PINNED" APPS
    nh_beta

    # CUSTOM APPS

    # Install global npm packages not available in nixpkgs repo
    # using node2nix and overlay (see above)
    # npmGlobals.functional-javascript-workshop
    # npmGlobals.how-to-markdown
    # npmGlobals.javascripting
    # npmGlobals.js-best-practices
    npmGlobals.learnyoubash
    # npmGlobals.regex-adventure
    # npmGlobals.zeal-user-contrib

    # GUI APPS
    # anki # this is currently marked as broken in all nix branches (as at 2025/01/01)
    # bitwarden-desktop
    # brave
    # dbeaver-bin
    # djview
    # google-chrome
    # goldendict-ng is currently only available for linux
    # obsidian
    # transmission_4
    # vlc-bin-universal
    # zoom-us
  ];
}
