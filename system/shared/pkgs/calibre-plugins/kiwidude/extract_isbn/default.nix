{ callPackage, ... }:
callPackage ../generic.nix { } {
  pname = "extract_isbn";
  version = "1.6.7";
  hash = "sha256-k4z6hUeD9PPAMlZzCiKVFUDOaqgWCuIMsyRvAm9TjNQ=";
  file = ./default.nix;
  zipName = "Extract ISBN.zip";
  meta = {
    description = "This plugin can be used to try to find the ISBN for a book using the text within a book format";
    homepage = "https://github.com/kiwidude68/calibre_plugins/tree/main/extract_isbn";
  };
}
