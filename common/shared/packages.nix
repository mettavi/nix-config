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

  # to prevent "make: *** No rule to make target 'install'.  Stop." error (missing install phase)
  zeal_mac = pkgs.zeal-qt6.overrideAttrs (oldAttrs: {
    installPhase = ''
      runHook preInstall

      mkdir -p "$out/Applications"
      cp -r *.app "$out/Applications"

      runHook postInstall
    '';
  });

  # place custom packages in one directory for ease of reference
  # each individual package is further defined in ../mypkgs/default.nx
  mypkgs = (pkgs.callPackage ../../mypkgs { });

in
{
  system.activationScripts = {

    extraActivation.text = ''
      # install the Karabiner Driver Kit .pkg from the nix store
      if [[ ! -d /Applications/.Karabiner-VirtualHIDDevice-Manager.app ]]; then
        sudo installer -pkg "${mypkgs.karabiner-driverkit}/Karabiner-DriverKit-VirtualHIDDevice-3.1.0.pkg" -target /
        "/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager" activate
      fi
      # Enable remote login for the host (macos ssh server)
      # WORKAROUND: `systemsetup -f -setremotelogin on` requires `Full Disk Access`
      # permission for the Application calling it
      if [[ "$(systemsetup -getremotelogin | sed 's/Remote Login: //')" == "Off" ]]; then
        launchctl load -w /System/Library/LaunchDaemons/ssh.plist
      fi
    '';
  };

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
    coreutils-prefixed
    cowsay
    darwin.trash
    exercism
    fastfetch
    ffmpeg
    gitleaks
    macfuse-stubs # Build time stubs for FUSE on macOS
    mas
    mkalias
    nix-fast-build # speed-up your evaluation and building process
    nixfmt-rfc-style
    nixd # nix language server
    nix-init # Generate Nix packages from URLs
    node2nix # Generate Nix expressions to build NPM packages
    ntfs3g # Read-write NTFS driver for FUSE
    nurl # generate Nix fetcher calls from repository URLs
    ocrmypdf
    pam-reattach # for touchid support in tmux (binary "reattach-to-session-namespace")
    pinentry_mac
    pinentry-tty # Passphrase entry dialog utilizing the Assuan protocol
    # pipx
    # pnpm
    # poppler
    # python-launcher
    ruby
    rustc
    shellcheck
    sops # Simple and flexible tool for managing secrets
    stow
    # texinfo # to read info files
    tldr
    tree
    wget
    xcodes
    zsh-completions
    zsh-powerlevel10k

    # "PINNED" APPS
    nh_beta

    # CUSTOM APPS
    mypkgs.karabiner-driverkit

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
    # appcleaner
    # bitwarden-desktop
    # brave
    # dbeaver-bin
    # djview
    # google-chrome
    # goldendict-ng is currently only available for linux
    # grandperspective
    # iina
    # iterm2
    # karabiner-elements
    keycastr # keystroke visualiser
    # keka
    # obsidian
    # picard
    # transmission_4
    # vlc-bin-universal

    # getting error "cannot download WhatsApp.app from any mirror"
    # fix was committed to master on Wed 18 Dec, see https://github.com/NixOS/nixpkgs/pull/365792/commits
    # whatsapp-for-mac
    zeal_mac
    # zoom-us
  ];
}
