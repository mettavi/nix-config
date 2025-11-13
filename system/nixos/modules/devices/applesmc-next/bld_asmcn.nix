{
  lib,
  kernel,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "applesmc-next";
  version = "0.1.6";

  src = fetchFromGitHub {
    owner = "c---";
    repo = "applesmc-next";
    rev = version;
    hash = "sha256-eXGs/5JZo5BIJtPUg++xaggSFkxyGXCUiDtgoj1tSuw=";
  };

  sourceRoot = "source/linux/v4l2loopback";
  hardeningDisable = [
    "pic"
    "format"
  ];

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = [
    "KERNELRELEASE=${kernel.modDirVersion}"
    "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "INSTALL_MOD_PATH=$(out)"
  ];

  meta = {
    description = "Patches to Linux kernel to allow setting battery charge thresholds on Apple devices";
    homepage = "https://github.com/c---/applesmc-next";
    license = lib.licenses.gpl2Only;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "applesmc-next";
    platforms = lib.platforms.all;
  };
}
