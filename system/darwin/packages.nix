{
  pkgs,
  ...
}:
let
  # this will point to a stable nixpkgs input rather than the default one
  # use "nixpkgs_name.package_name" to install a non-default package
  # nixpkgs-24_11 = inputs.nixpkgs-24_11.legacyPackages.${system};
  # nixpkgs-24_05 = inputs.nixpkgs-24_05.legacyPackages.${system};

in
{

  # install standard packages
  environment.systemPackages = with pkgs; [
    # Uninstall unwanted apps
    appcleaner
    coreutils-prefixed
    darwin.trash
    # grandperspective
    # iina
    # iterm2
    # karabiner-elements
    # keka
    keycastr # keystroke visualiser
    # Build time stubs for FUSE on macOS NB: this requires the full macFUSE package (see brew.nix)
    macfuse-stubs
    # pam-reattach # for touchid support in tmux (binary "reattach-to-session-namespace")
    # getting error "cannot download WhatsApp.app from any mirror"
    # fix was committed to master on Wed 18 Dec, see https://github.com/NixOS/nixpkgs/pull/365792/commits
    # whatsapp-for-mac
    xcodes
    # Move to homebrew modules as this package is unable to install the Word plugin
    # zotero # Collect, organize, cite, and share your research sources

    # CUSTOM APPS
    macpkgs.goldendictng-gh # Advanced multi-dictionary lookup program
    macpkgs.karabiner-driverkit
    macpkgs.libation-gh # Audible audiobook manager
    macpkgs.stacher # A modern GUI for yt-dlp
  ];
}
