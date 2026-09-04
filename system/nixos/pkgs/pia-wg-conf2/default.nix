{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:

buildGoModule (finalAttrs: {
  pname = "pia-wg-config2";
  version = "1.0.5";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "Ephemeral-Dust";
    repo = "pia-wg-config";
    rev = "v${finalAttrs.version}";
    hash = "sha256-4FTFIdS0QJ+3lMkH2urJU0WgZtmswXlLTpPujFM6DEw=";
  };

  vendorHash = null;

  ldflags = [
    "-s"
    "-w"
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "A Wireguard config generator for Private Internet Access";
    homepage = "https://github.com/Ephemeral-Dust/pia-wg-config";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "pia-wg-config";
  };
})
