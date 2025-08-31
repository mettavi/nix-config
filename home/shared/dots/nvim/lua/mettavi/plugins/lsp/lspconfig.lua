return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
  },
  config = function()
    local keymap = vim.keymap -- for conciseness

    -- import lspconfig plugin
    local lspconfig = vim.lsp.config

    -- import cmp-nvim-lsp plugin
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    -- enable autocompletion via nvim-cmp (assign to every lsp server config)
    -- by extending the capabilities of lsp/neovim with nvim-cmp
    local capabilities = cmp_nvim_lsp.default_capabilities()

    local hostname = nixCats.extra("hostname")
    local isDarwin = nixCats.extra("isDarwin")

    vim.lsp.config("*", {
      capabilities = capabilities,
    })

    vim.lsp.enable({
      "bashls",
      "lua_ls",
      "nixd",
      "taplo",
      "ts_ls",
      "yamlls",
    })

    -- Server-specific settings. See `:help lsp-quickstart`
    vim.lsp.config("lua_ls", {
      settings = {
        Lua = {
          completion = {
            callSnippet = "Replace",
          },
          -- make the language server recognize "vim" global
          diagnostics = {
            globals = { "vim" },
          },
          hint = {
            enable = true, -- necessary for inlay hints
          },
        },
      },
    })

    local platform
    if isDarwin then
      platform = "darwinConfigurations"
    else
      platform = "nixosConfigurations"
    end

    vim.lsp.config("nixd", {
      cmd = { "nixd" },
      settings = {
        nixd = {
          nixpkgs = {
            expr = "import <nixpkgs> { }",
          },
          formatting = {
            command = { "nixfmt" },
          },
          -- diagnostic = { suppress = { "sema-unused-def-lambda-witharg-formal" } },
          options = {
            darwin = { expr = '(builtins.getFlake ("git+file://" + toString ./.)).darwinConfigurations.mack.options' },
            -- sysopt = {
            --   expr = string.format(
            --     '(builtins.getFlake ("git+file://" + toString ./.)).[%s].[%s].options',
            --     platform,
            --     hostname
            --   ),
            -- },
            -- nixd cannot get home-manager options when installed as a nix-darwin module
            -- ( See https://github.com/nix-community/nixd/issues/608 )
            homeopt = {
              expr = string.format(
                '(builtins.getFlake ("git+file://" + toString ./.)).[%s].[%s].options.home-manager.users.type.getSubOptions []',
                platform,
                hostname
              ),
            },
            -- Before configuring Home Manager options, consider your setup:
            -- Which command do you use for home-manager switching?
            --
            --  A. home-manager switch --flake .#... (standalone Home Manager)
            -- expr = "(builtins.getFlake (builtins.toString ./.)).homeConfigurations.<name>.options",
            --  B. nixos-rebuild switch --flake .#... (NixOS with integrated Home Manager)
            -- expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.<name>.options.home-manager.users.type.getSubOptions []".
          },
        },
      },
    })

    local tsinlayHints = {
      includeInlayParameterNameHints = "all",
      includeInlayParameterNameHintsWhenArgumentMatchesName = false,
      includeInlayFunctionParameterTypeHints = true,
      includeInlayVariableTypeHints = true,
      includeInlayVariableTypeHintsWhenTypeMatchesName = false,
      includeInlayPropertyDeclarationTypeHints = true,
      includeInlayFunctionLikeReturnTypeHints = true,
      includeInlayEnumMemberValueHints = true,
    }
    vim.lsp.config("ts_ls", {
      settings = {
        typescript = {
          inlayHints = {
            tsinlayHints,
          },
        },
        javascript = {
          inlayHints = {
            tsinlayHints,
          },
        },
      },
      implicitProjectConfiguration = {
        checkJs = true,
      },
    })

    lspconfig("yamlls", {
      settings = {
        yaml = {
          schemaStore = {
            -- must disable built-in schemaStore support if you want to use
            -- the neovim schemastore plugin and its advanced options like `ignore`.
            enable = false,
            -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
            url = "",
          },
          schemas = require("schemastore").yaml.schemas(),
          -- using yamlfmt for formatting
          format = {
            enable = false,
          },
        },
      },
    })

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local opts = { buffer = ev.buf, silent = true }

        -- set keybinds
        opts.desc = "Show LSP references"
        keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

        opts.desc = "Go to declaration"
        keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

        opts.desc = "Show LSP definitions"
        keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

        opts.desc = "Show LSP implementations"
        keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

        opts.desc = "Show LSP type definitions"
        keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

        opts.desc = "See available code actions"
        keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

        opts.desc = "Smart rename"
        keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

        opts.desc = "Show buffer diagnostics"
        keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

        opts.desc = "Show line diagnostics"
        keymap.set("n", "<leader>dl", vim.diagnostic.open_float, opts) -- show diagnostics for line, j/k to close

        opts.desc = "Show documentation for what is under cursor"
        keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

        opts.desc = "Restart LSP"
        keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
      end,
    })

    -- Change the Diagnostic symbols in the sign column (gutter)
    vim.diagnostic.config({
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = " ",
          [vim.diagnostic.severity.WARN] = " ",
          [vim.diagnostic.severity.INFO] = "󰋼 ",
          [vim.diagnostic.severity.HINT] = "󰌵 ",
        },
        numhl = {
          [vim.diagnostic.severity.ERROR] = "",
          [vim.diagnostic.severity.WARN] = "",
          [vim.diagnostic.severity.HINT] = "",
          [vim.diagnostic.severity.INFO] = "",
        },
      },
    })
  end,
}
