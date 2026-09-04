{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:

buildGoModule (finalAttrs: {
  pname = "pia-wg-config";
  version = "1.1.1";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "kylegrantlucas";
    repo = "pia-wg-config";
    rev = "v${finalAttrs.version}";
    hash = "sha256-nVdmh9wOZBxbMOgMnC6nEsoaEh6cQ6o1ok+OONopXro=";
  };

  vendorHash = null;

  ldflags = [
    "-s"
    "-w"
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "A Wireguard config generator for Private Internet Access";
    homepage = "https://github.com/kylegrantlucas/pia-wg-config";
    changelog = "https://github.com/kylegrantlucas/pia-wg-config/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "pia-wg-config";
  };
})
