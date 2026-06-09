{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  hatchling,
  nix-update-script,
}:

buildPythonPackage (finalAttrs: {
  pname = "python-gedcom";
  version = "1.1.0";
  pyproject = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "nickreynke";
    repo = "python-gedcom";
    tag = "v${finalAttrs.version}";
    hash = "sha256-3q7dPFIbBYU9HPBTmq5Ch51WVzGWuPD/qTc+GjfDV1Q=";
  };

  build-system = [
    hatchling
  ];

  pythonImportsCheck = [
    "python_gedcom"
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Python module for parsing, analyzing, and manipulating GEDCOM files";
    homepage = "https://github.com/nickreynke/python-gedcom";
    changelog = "https://github.com/nickreynke/python-gedcom/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.gpl2Only;
    maintainers = with lib.maintainers; [ ];
  };
})
