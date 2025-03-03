{
  pkgs,
  ...
}:
let
  # this will point to a stable nixpkgs input rather than the default one
  # use "nixpkgs_name.package_name" to install a non-default package
  # nixpkgs-24_11 = inputs.nixpkgs-24_11.legacyPackages.${system};
  # nixpkgs-24_05 = inputs.nixpkgs-24_05.legacyPackages.${system};

  # place custom packages in one directory for ease of reference
  # each individual package is further defined in ./pkgs/default.nx
  mypkgs = (pkgs.callPackage ./pkgs { });

  # to prevent "make: *** No rule to make target 'install'.  Stop." error (missing install phase)
  zeal_mac = pkgs.zeal-qt6.overrideAttrs (oldAttrs: {
    installPhase = ''
      runHook preInstall

      mkdir -p "$out/Applications"
      cp -r *.app "$out/Applications"

      runHook postInstall
    '';
  });

in
{
  system.activationScripts = {

    extraActivation.text = ''
      # install the Karabiner Driver Kit .pkg from the nix store
      if [[ ! -d /Applications/.Karabiner-VirtualHIDDevice-Manager.app ]]; then
        sudo installer -pkg "${mypkgs.karabiner-driverkit}/Karabiner-DriverKit-VirtualHIDDevice-5.0.0.pkg" -target /
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
    # appcleaner
    coreutils-prefixed
    darwin.trash
    # grandperspective
    # iina
    # iterm2
    # karabiner-elements
    # keka
    keycastr # keystroke visualiser
    macfuse-stubs # Build time stubs for FUSE on macOS
    mas
    pam-reattach # for touchid support in tmux (binary "reattach-to-session-namespace")
    pinentry_mac
    # getting error "cannot download WhatsApp.app from any mirror"
    # fix was committed to master on Wed 18 Dec, see https://github.com/NixOS/nixpkgs/pull/365792/commits
    # whatsapp-for-mac
    xcodes
    zeal_mac

    # CUSTOM APPS
    mypkgs.karabiner-driverkit
    mypkgs.libation # Audible audiobook manager
  ];
}
