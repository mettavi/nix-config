return {
  "nixd",
  enabled = nixInfo.isNix, -- mason doesn't have nixd
  for_cat = "nix",
  lsp = {
    filetypes = { "nix" },
    settings = {
      nixd = {
        nixpkgs = {
          expr = [[import <nixpkgs> {}]],
        },
        options = {
          -- Before configuring Home Manager options, consider your setup:
          -- Which command do you use for home-manager switching?
          --
          --  A. home-manager switch --flake .#... (standalone Home Manager)
          -- expr = "(builtins.getFlake (builtins.toString ./.)).homeConfigurations.<name>.options",
          --  B. nixos-rebuild switch --flake .#... (NixOS with integrated Home Manager)
          -- expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.<name>.options.home-manager.users.type.getSubOptions []".
          hm_nixos = {
            expr = string.format(
              "(builtins.getFlake (builtins.toString ./.)).%s.%s.options.home-manager.users.type.getSubOptions []",
              "nixosConfigurations",
              vim.uv.os_gethostname()
            ),
          },
          hm_darwin = {
            expr = string.format(
              "(builtins.getFlake (builtins.toString ./.)).%s.%s.options.home-manager.users.type.getSubOptions []",
              "darwinConfigurations",
              vim.uv.os_gethostname()
            ),
          },
        },
        formatting = {
          command = { "nixfmt" },
        },
        diagnostic = {
          suppress = {
            "sema-escaping-with",
            "sema-unused-def-lambda-witharg-formal",
          },
        },
      },
    },
  },
}
