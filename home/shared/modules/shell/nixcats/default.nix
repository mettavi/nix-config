{
  config,
  darwinConfig,
  inputs,
  lib,
  ...
}:

with lib;
let
  utils = inputs.nixCats.utils;
  cfg = config.nyx.modules.shell.nixcats;
in
{
  imports = [
    inputs.nixCats.homeModule
  ];

  options.nyx.modules.shell.nixcats = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install and configure neovim using the nixCats system";
    };
  };

  config = mkIf cfg.enable {
    # this value, nixCats is the defaultPackageName you pass to utils.mkNixosModules and utils.mkHomeModules
    # and it controls the name of the top level option set.
    # If you made a package named `nixCats` your default package as we did here,
    # the modules generated would be set at:
    # config.nixCats = {
    #   enable = true;
    #   packageNames = [ "nixCats" ]; # <- the packages you want installed
    #   <see :h nixCats.module for options>
    # }
    nixCats = {
      enable = true;
      # nixpkgs_version = inputs.nixpkgs;
      # this will add the overlays from ./overlays and also,
      # add any plugins in inputs named "plugins-pluginName" to pkgs.neovimPlugins
      # It will not apply to overall system, just nixCats.
      addOverlays = # (import ./overlays inputs) ++
        [
          (utils.standardPluginOverlay inputs)
        ];
      # see the packageDefinitions below.
      # This says which of those to install.
      packageNames = [ "nvim" ];

      luaPath = ../../../dots/nvim;

      # the .replace vs .merge options are for modules based on existing configurations,
      # they refer to how multiple categoryDefinitions get merged together by the module.
      # for useage of this section, refer to :h nixCats.flake.outputs.categories
      categoryDefinitions.replace = (
        {
          pkgs,
          settings,
          categories,
          extra,
          name,
          mkPlugin,
          ...
        }@packageDef:
        {
          # to define and use a new category, simply add a new list to a set here,
          # and later, you will include categoryname = true; in the set you
          # provide when you build the package using this builder function.
          # see :help nixCats.flake.outputs.packageDefinitions for info on that section.

          # lspsAndRuntimeDeps:
          # this section is for dependencies that should be available
          # at RUN TIME for plugins. Will be available to PATH within neovim terminal
          # this includes LSPs
          lspsAndRuntimeDeps = {
            general = with pkgs; [
              prettier
              taplo
              typescript-language-server
            ];
            bash = with pkgs; [
              bash-language-server
              shfmt
            ];
            lua = with pkgs; [
              lua-language-server
              stylua
            ];
            nix = with pkgs; [
              nixd
              nixfmt
            ];
            yaml = with pkgs; [
              yaml-language-server
              yamlfmt
              yamllint
            ];
          };
          # themer = with pkgs; [
          #   # you can even make subcategories based on categories and settings sets!
          #   (builtins.getAttr packageDef.categories.colorscheme {
          #       "onedark" = onedark-vim;
          #       "catppuccin" = catppuccin-nvim;
          #       "catppuccin-mocha" = catppuccin-nvim;
          #       "tokyonight" = tokyonight-nvim;
          #       "tokyonight-day" = tokyonight-nvim;
          #     }
          #   )
          # ];
          # This is for plugins that will load at startup without using packadd:
          startupPlugins = {
            general = with pkgs.vimPlugins; [
              # NB: lazy doesnt care if these are in startupPlugins or optionalPlugins
              # also you dont have to download everything via nix if you dont want.
              # but you have the option, and that is demonstrated here.
              # lazy loading isnt required with a config this small
              # but as a demo, we do it anyway.
              noice-nvim
              telescope-nvim
              telescope-fzf-native-nvim
              # This is for if you only want some of the grammars
              # (nvim-treesitter.withPlugins (
              #   plugins: with plugins; [
              #     nix
              #     lua
              #   ]
              # ))
              # sometimes you have to fix some names
              # {
              #   plugin = catppuccin-nvim;
              #   name = "catppuccin";
              # }
              # you could do this within the lazy spec instead if you wanted
              # and get the new names from `:NixCats pawsible` debug command
            ];
          };
          # not loaded automatically at startup.
          # use with packadd and an autocommand in config to achieve lazy loading
          # NB: this template is using lazy.nvim so, which list you put them in is irrelevant.
          # startupPlugins or optionalPlugins, it doesnt matter, lazy.nvim does the loading.
          # I just put them all in startupPlugins. I could have put them all in here instead.
          optionalPlugins = { };
          # shared libraries to be added to LD_LIBRARY_PATH
          # variable available to nvim runtime
          # sharedLibraries = {
          #   general = with pkgs; [ ];
          # };
          # environmentVariables:
          # this section is for environmentVariables that should be available
          # at RUN TIME for plugins. Will be available to path within neovim terminal
          # environmentVariables = {
          # test = {
          #   CATTESTVAR = "It worked!";
          # };
          # };
          # categories of the function you would have passed to
          # python.withPackages or lua.withPackages
          # get the path to this python environment
          # in your lua config via
          # vim.g.python3_host_prog
          # or run from nvim terminal via :!<packagename>-python3
          # do not forget to set `hosts.python3.enable` in package settings

          # get the path to this python environment
          # in your lua config via
          # vim.g.python3_host_prog
          # or run from nvim terminal via :!<packagename>-python3
          # python3.libraries = {
          # test = [ (_:[]) ];
          # };
          # populates $LUA_PATH and $LUA_CPATH
          # extraLuaPackages = {
          # test = [ (_: [ ]) ];
          # };
          # If you know what these are, you can provide custom ones by category here.
          # If you dont, check this link out:
          # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
          # extraWrapperArgs = {
          # test = [
          #   '' --set CATTESTVAR2 "It worked again!"''
          # ];
          # };
        }
      );
      # And then build a package with specific categories from above here:
      # All categories you wish to include must be marked true,
      # but false may be omitted.
      # This entire set is also passed to nixCats for querying within the lua.
      # see :help nixCats.flake.outputs.packageDefinitions
      packageDefinitions.replace = {
        # These are the names of your packages
        # and also the default command names for them.
        # you can include as many as you wish.
        nvim =
          { pkgs, name, ... }:
          {
            # these also receive our pkgs variable
            # see :help nixCats.flake.outputs.packageDefinitions
            # they contain a settings set defined above
            # see :help nixCats.flake.outputs.settings
            settings = {
              suffix-path = true;
              suffix-LD = true;
              wrapRc = true;
              # set a default so the lazy-lock.json will be loaded from here regardless of the status of wrapRc (see init.lua)
              unwrappedCfgPath = utils.mkLuaInline "os.getenv('HOME') .. '/.nix-config/home/shared/dots/nvim'";
              # unwrappedCfgPath = "/path/to/here";
              # IMPORTANT:
              # your alias may not conflict with your other packages.
              aliases = [
                "nv"
              ];
              # neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
              # hosts.python3.enable = true;
              # hosts.node.enable = true;
            };
            # and a set of categories that you want
            # (and other information to pass to lua)
            categories = {
              general = true;
              bash = true;
              lua = true;
              nix = true;
              yaml = true;

              # we can pass whatever we want actually.
              # have_nerd_font = false;
              # example = {
              #   youCan = "add more than just booleans";
              #   toThisSet = [
              #     "and the contents of this categories set"
              #     "will be accessible to your lua with"
              #     "nixCats('path.to.value')"
              #     "see :help nixCats"
              #     "and type :NixCats to see the categories set in nvim"
              #   ];
              # };
            };
            extra = {
              # there is also an extra table you can use to pass extra stuff.
              # anything else to pass and grab in lua with `nixCats.extra`
              # to keep the categories table from being filled with non category things that you want to pass
              # but you can pass all the same stuff in any of these sets and access it in lua
              # pass boolean to neovim lua config for transparency in iterm2
              isItermTrans = darwinConfig.nyx.modules.system.apps.iterm2.transparency or false;
            };
            # extra = {
            #   nixdExtras.nixpkgs = ''import ${pkgs.path} {}'';
            # };
          };
        # an extra test package with normal lua reload for fast edits
        # nix doesnt provide the config in this package, allowing you free reign to edit it.
        # then you can swap back to the normal pure package when done.
        testnvim =
          { pkgs, mkPlugin, ... }:
          {
            settings = {
              suffix-path = true;
              suffix-LD = true;
              # IMPURE PACKAGE: normal config reload
              # include same categories as main config,
              # will load from vim.fn.stdpath('config')
              wrapRc = false;
              # or tell it some other place to load
              # unwrappedCfgPath = "/some/path/to/your/config";
              unwrappedCfgPath = utils.mkLuaInline "os.getenv('HOME') .. '/.nix-config/home/shared/dots/nvim'";
              # configDirName: will now look for nixCats-nvim within .config and .local and others
              # this can be changed so that you can choose which ones share data folders for auths
              # :h $NVIM_APPNAME
              configDirName = "nixCats-nvim";
              aliases = [ "testCat" ];
              # If you wanted nightly, uncomment this, and the flake input.
              # neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
              # Probably add the cache stuff they recommend too.
            };
            categories = {
              general = true;
              test = false;
            };
            extra = { };
          };
      };
    };
    programs.zsh.shellGlobalAliases = {
      nvc = "cd ~/.config/nvim";
      nvs = "cd ~/.local/share/nvim";
    };
  };
}
