{
  config,
  inputs,
  lib,
  ...
}:
with lib;
let
  cfg = config.mettavi.shell.nvim-lib;
in
{
  # import the neovim wrapper module
  imports = [
    (inputs.wrappers.lib.getInstallModule {
      name = "neovim";
      value = inputs.wrappers.lib.wrapperModules.neovim;
    })
  ];

  options.mettavi.shell.nvim-lib = {
    enable = mkEnableOption "set up and configure the nvim wrapper module";
    cats = lib.mkOption {
      readOnly = true;
      type = lib.types.attrsOf lib.types.bool;
      default = builtins.mapAttrs (_: v: v.enable) config.specs;
    };
  };

  config = mkIf cfg.enable {
    wrappers.neovim =
      {
        config,
        pkgs,
        wlib,
        ...
      }:
      let
        neovimPlugins = config.nvim-lib.pluginsFromPrefix "plugins-" inputs;
      in
      {
        imports = [ ./extPlugins.nix ];

        enable = true;
        env.NVIM_APPNAME = "nvim-wrap";
        # If you want to install multiple neovim derivations via home.packages or environment.systemPackages
        # in order to prevent path collisions:
        # set this to true:
        settings.dont_link = true;
        # and make sure these dont share values:
        binName = "nvw";
        # settings.aliases = [ ];

        settings.config_directory = ./config;

        specMods =
          {
            # When this module is run in an inner list,
            # this will contain `config` of the parent spec
            parentSpec ? null,
            # and this will contain `options`
            # otherwise they will be `null`
            parentOpts ? null,
            parentName ? null,
            # and then config from this one, as normal
            config,
            # and the other module arguments.
            ...
          }:
          {
            options.extraPackages = lib.mkOption {
              type = lib.types.listOf wlib.types.stringable;
              default = [ ];
              description = "an extraPackages spec field to put packages to suffix to the PATH";
            };
          };

        # get extraPackages as sub-options under specs.<name>.extraPackages, rather than at the top level
        extraPackages = config.specCollect (acc: v: acc ++ (v.extraPackages or [ ])) [ ];

        specs.general = {
          data = with pkgs.vimPlugins; [
            auto-session
            better-escape-nvim
            bufferline-nvim
            harpoon
            # lazydev-nvim
            lualine-nvim
            # lze
            # lzextras
            nvim-tree-lua
            SchemaStore-nvim
            tokyonight-nvim
            # treesitter + grammars
            # nvim-treesitter.withAllGrammars
            # This is for if you only want some of the grammars
            (nvim-treesitter.withPlugins (
              plugins: with plugins; [
                json
                javascript
                typescript
                tsx
                yaml
                html
                css
                markdown
                markdown_inline
                bash
                lua
                vim
                dockerfile
                gitignore
                query
                vimdoc
                c
                toml
                regex
                nix
              ]
            ))
            treesitter-modules-nvim
            vim-tmux-navigator
          ];
          extraPackages = with pkgs; [
            lazygit
            prettier
            taplo
            tree-sitter
            typescript-language-server
          ];
        };

        # If the defaults are fine, you can just provide the `.data` field
        # In this case, a list of specs, instead of a single plugin like above
        specs.lze = [
          # if defaults is fine, you can just provide the `.data` field
          neovimPlugins.lze
          # but these can be specs too!
          {
            # these ones can't take lists though
            data = neovimPlugins.lzextras;
            # things can target any spec that has a name.
            name = "lzextras";
            # now something else can be after = [ "lzextras" ]
            # the spec name is not the plugin name.
            # to override the plugin name, use `pname`
            # You could run something before your main init.lua like this
            # before = [ "INIT_MAIN" ];
            # You can include configuration and translated nix values here as well!
            # type = "lua"; # | "fnl" | "vim"
            # info = { };
            # config = ''
            #   local info, pname, lazy = ...
            # '';
          }
        ];

        specs.vim-maximizer = neovimPlugins.vim-maximizer;

        specs.lazy = {
          # this would ensure any config included from nix in here will be ran after any provided by the `lze` spec
          # If we provided any from within either spec, anyway
          after = [ "lze" ];
          # note we didn't have to specify the `lze` specs name, because it was a top level spec
          # this `lazy = true` definition will transfer to specs in the contained DAL, if there is one.
          # This is because the definition of lazy in `config.specMods` checks `parentSpec.lazy or false`
          # the submodule type for `config.specMods` gets `parentSpec` as a `specialArg`.
          # you can define options like this too!
          lazy = true;
          # here we chose a DAL of plugins, but we can also pass a single plugin, or null
          # plugins are of type wlib.types.stringable
          # plugins which are not loaded until you vim.cmd.packadd them ...
          data = with pkgs.vimPlugins; [
            # {
            #   data = telescope-nvim;
            #   # You can override defaults from the parent spec here
            #   lazy = false;
            # }
            alpha-nvim
            # blink-cmp
            # blink-compat
            comment-nvim
            conform-nvim
            cmp-buffer
            cmp-cmdline
            cmp_luasnip
            cmp-nvim-lsp
            cmp-path
            # colorful-menu-nvim
            dressing-nvim # very lazy
            # fidget-nvim
            flash-nvim # very lazy
            friendly-snippets
            gitsigns-nvim
            indent-blankline-nvim
            lazygit-nvim
            lspkind-nvim
            lualine-nvim
            luasnip
            noice-nvim # very lazy
            nui-nvim
            nvim-autopairs
            nvim-cmp
            nvim-lint
            nvim-lspconfig
            nvim-lsp-file-operations
            nvim-notify
            nvim-surround
            nvim-treesitter-textobjects
            nvim-ts-autotag
            nvim-ts-context-commentstring
            nvim-web-devicons
            plenary-nvim
            render-markdown-nvim
            # snacks-nvim
            substitute-nvim
            telescope-nvim
            todo-comments-nvim
            trouble-nvim
            # vim-startuptime
            which-key-nvim # very lazy
          ];
        };

        # You can use the before and after fields to run them before or after other specs or spec of lists of specs
        specs.lua = {
          after = [ "lazy" ];
          lazy = true;
          data = with pkgs.vimPlugins; [
            lazydev-nvim
          ];
          extraPackages = with pkgs; [
            lua-language-server
            stylua
          ];
        };
        specs.nix = {
          data = null;
          extraPackages = with pkgs; [
            nixd
            nixfmt
          ];
        };

        specs.bash = {
          data = null;
          extraPackages = with pkgs; [
            bash-language-server
            shfmt
          ];
        };
        specs.yaml = {
          data = null;
          extraPackages = with pkgs; [
            yaml-language-server
            yamlfmt
            yamllint
          ];
        };
      };

    #
    #
    #
    # info = {
    #   values = "for lua";
    #   which = "will be placed in the generated info plugin for access";
    # };
    #

    home.sessionVariables =
      let
        # You can still grab the value from config if desired!
        nvimpath = lib.getExe config.wrappers.neovim.wrapper;
      in
      {
        EDITOR = nvimpath;
        MANPAGER = "${nvimpath} +Man!";
      };
    xdg.configFile = {
      "nvim-wrap".source = ./config;
    };
  };
}
