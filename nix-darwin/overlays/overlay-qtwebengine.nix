{
  pkgs,
  lib,
  ...
}:
{
  nixpkgs.overlays = [
    (
      final: prev:
      let
        # Error when using clang 16:
        # .../src/3rdparty/chromium/base/containers/flat_tree.h:354:22:
        # error: invalid operands to binary expression ('const container_type' (aka 'const std::vector<device::BluetoothUUID>') and 'const container_type')
        #    return lhs.body_ <=> rhs.body_;
        #           ~~~~~~~~~ ^   ~~~~~~~~~
        stdenv' = if stdenv.cc.isClang then llvmPackages_17.stdenv else stdenv;
        inherit (pkgs)
          llvmPackages_17
          buildPackages
          systemd
          stdenv
          pciutils
          xcbuild
          ;
      in
      {
        qt6 = prev.qt6.overrideScope (
          final: prev: {
            qtwebengine = prev.qtwebengine.overrideAttrs (oldAttrs: {
              stdenv = stdenv'; 
              postPatch =
                ''
                  # Patch Chromium build tools
                  (
                    cd src/3rdparty/chromium;
                    # Manually fix unsupported shebangs
                    substituteInPlace third_party/harfbuzz-ng/src/src/update-unicode-tables.make \
                      --replace "/usr/bin/env -S make -f" "/usr/bin/make -f" || true
                    substituteInPlace third_party/webgpu-cts/src/tools/run_deno \
                      --replace "/usr/bin/env -S deno" "/usr/bin/deno" || true
                    patchShebangs .
                  )
                  substituteInPlace cmake/Functions.cmake \
                    --replace "/bin/bash" "${buildPackages.bash}/bin/bash"
                  # Patch library paths in sources
                  substituteInPlace src/core/web_engine_library_info.cpp \
                    --replace "QLibraryInfo::path(QLibraryInfo::DataPath)" "\"$out\"" \
                    --replace "QLibraryInfo::path(QLibraryInfo::TranslationsPath)" "\"$out/translations\"" \
                    --replace "QLibraryInfo::path(QLibraryInfo::LibraryExecutablesPath)" "\"$out/libexec\""
                  substituteInPlace configure.cmake src/gn/CMakeLists.txt \
                    --replace "AppleClang" "Clang"
                  # Disable metal shader compilation, Xcode only
                  substituteInPlace src/3rdparty/chromium/third_party/angle/src/libANGLE/renderer/metal/metal_backend.gni \
                    --replace-fail 'angle_has_build && !is_ios && target_os == host_os' "false"
                ''
                + lib.optionalString stdenv.hostPlatform.isLinux ''
                  sed -i -e '/lib_loader.*Load/s!"\(libudev\.so\)!"${lib.getLib systemd}/lib/\1!' \
                    src/3rdparty/chromium/device/udev_linux/udev?_loader.cc
                  sed -i -e '/libpci_loader.*Load/s!"\(libpci\.so\)!"${pciutils}/lib/\1!' \
                    src/3rdparty/chromium/gpu/config/gpu_info_collector_linux.cc
                ''
                + lib.optionalString stdenv.hostPlatform.isDarwin ''
                    substituteInPlace cmake/Functions.cmake \
                  --replace "/usr/bin/xcrun" "${xcbuild}/bin/xcrun"
                '';
            });
          }
        );
      }
    )
  ];

}
