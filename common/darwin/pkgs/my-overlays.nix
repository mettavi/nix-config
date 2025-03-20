{
  # there is also a overlays submodule included in the imports list
  nixpkgs.overlays = [
    (final: prev: {
      goldendictng-gh = final.callPackage ./goldendictng-gh { };
      karabiner-driverkit = final.callPackage ./karabiner-driverkit { };
      libation-gh = final.callPackage ./libation-gh { };
    })
  ];
}
