# Finish installing Karabiner Driver Kit from nix-store

NIXPATH=${myPkgs.karabiner-driver}
NIXLIB="$NIXPATH/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice" 
LIBPATH="/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice"

if [[ ! -e "/Applications/.Karabiner-VirtualHIDDevice-Manager.app" ]]; then
  cp -r "$NIXPATH/Apps/.Karabiner-VirtualHIDDevice-Manager.app" /Applications
fi

if [[ ! -e "$LIBPATH/Applications/Karabiner-VirtualHIDDevice-Daemon.app" ]]; then
  mkdir -p "$LIBPATH/Applications" 
  cp -r "$NIXLIB/Applications/Karabiner-VirtualHIDDevice-Daemon.app" "$LIBPATH/Applications/"
fi

if [[ ! -d "$LIBPATH/scripts" ]]; then
  mkdir -p "$LIBPATH/scripts/uninstall"
  cp -r "$NIXLIB/scripts" "$LIBPATH"
fi
