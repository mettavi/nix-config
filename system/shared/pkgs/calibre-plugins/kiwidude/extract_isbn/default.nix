{ callPackage, lib }:
callPackage ../generic.nix { } {
  pname = "extract_isbn";
  version = "1.6.6";
  hash = "sha256-SJc6CDdg1Da8SCLv4AeSkxZOcH26AHZ1xa4UEjXN8zM=";
  zipName = "Extract ISBN.zip";
  meta = {
    description = "This plugin can be used to try to find the ISBN for a book using the text within a book format";
    homepage = "https://github.com/kiwidude68/calibre_plugins/tree/main/extract_isbn";
    changelog = "https://github.com/kiwidude68/calibre_plugins/releases/tag/extract_isbn-v1.6.6";
    maintainers = with lib.maintainers; [ mettavi ];
  };
}
