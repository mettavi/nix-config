{
  lib,
  fetchFromGitHub,
  buildGoModule,
  nix-update-script,
}:

buildGoModule (finalAttrs: {
  pname = "pia-wg-cfg";
  version = "1.4.0";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "ccarpinteri";
    repo = "pia-wg-config";
    tag = "v${finalAttrs.version}";
    hash = "sha256-O2iZp+YyMagDCEcXJDa+4Jdp5YWD9O9gec3WqYHB/vY=";
  };

  vendorHash = null;

  ldflags = [ "-s" ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "A Wireguard config generator for Private Internet Access";
    homepage = "https://github.com/ccarpinteri/pia-wg-config";
    changelog = "https://github.com/ccarpinteri/pia-wg-config/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "pia-wg-config";
  };
})
