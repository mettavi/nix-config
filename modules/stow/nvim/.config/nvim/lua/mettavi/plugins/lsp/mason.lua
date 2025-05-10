return {
  "mason-org/mason.nvim",
  dependencies = {
    "mason-org/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    "jay-babu/mason-nvim-dap.nvim",
  },
  config = function()
    -- import lspconfig plugin
    require("lspconfig")

    -- import cmp-nvim-lsp plugin
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    -- import lspconfig plugin
    local lspconfig = require("lspconfig")

    -- enable autocompletion via nvim-cmp (assign to every lsp server config)
    -- by extending the cpabilities of lsp/neovim with nvim-cmp
    local capabilities = cmp_nvim_lsp.default_capabilities()

    -- code to run when lsp attaches to buffer (assign to everyl lsp server config)
    local on_attach = function(client, bufnr)
      -- inlay hints (experimental), need to turn it on manually
      local function buf_command(...)
        vim.api.nvim_buf_create_user_command(bufnr, ...)
      end
      if client.server_capabilities.inlayHintProvider and vim.fn.has("nvim-0.10") > 0 then
        local inlay = function(enable)
          if enable == "toggle" then
            enable = not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
          end
          vim.lsp.inlay_hint.enable(enable, { bufnr = bufnr })
        end
        vim.api.nvim_create_user_command("ToggleInlayHints", "InlayHintsToggle", {})
        buf_command("InlayHintsToggle", function(_)
          inlay("toggle")
        end, { nargs = 0, desc = "Toggle inlay hints." })
        buf_command("ToggleInlayHints", "InlayHintsToggle", {})
        -- Toggling inlay hints: gh
        vim.keymap.set("n", "gh", "<cmd>InlayHintsToggle<CR>", { buffer = true })
      else
        print("no inlay hints available")
      end
    end

    -- import mason
    local mason = require("mason")

    -- import mason-lspconfig
    local mason_lspconfig = require("mason-lspconfig")

    local mason_tool_installer = require("mason-tool-installer")

    local mason_nvim_dap = require("mason-nvim-dap")

    -- enable mason and configure icons
    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    -- mason_lspconfig.setup({ -- use mason_tool_installer instead to also autoupdate
    -- list of servers for mason to install
    -- ensure_installed = {
    --   "ts_ls",
    --   "html",
    --   "cssls",
    --   "tailwindcss",
    --   "svelte",
    --   "lua_ls",
    --   "emmet_ls",
    --   "pyright",
    --   "bashls", -- uses shellcheck linter installed with brew
    -- },
    -- auto-install configured servers (with lspconfig)
    -- automatic_installation = true, -- not the same as ensure_installed
    -- })

    mason_tool_installer.setup({
      ensure_installed = {
        "ts_ls", -- typescript language server
        "eslint_d", -- js linter
        "html", -- HTML language server
        "cssls", -- CSS language server
        "tailwindcss", -- tailwind CSS language server
        "emmet_ls", -- emmet language server (HTML/XML/CSS...)
        "svelte", -- svelte language server (HTML/CSS/JS)
        "pyright", -- python language server
        "pylint", -- python linter
        "isort", -- python formatter
        "black", -- python formatter
        "lua_ls", -- lua language server
        "stylua", -- lua formatter
        "bashls", -- bash language server, uses shellcheck linter installed with brew
        "shfmt", -- bash formatter
        "taplo", -- toml ls and formatter
        "yamlls", -- Language Server for YAML Files
        "yamllint", -- Linter for YAML files
        "yamlfmt", -- tool or library to format yaml files
        "prettier", -- multi-purpose formatter
      },
      -- if set to true this will check each tool for updates. If updates
      -- are available the tool will be updated. This setting does not
      -- affect :MasonToolsUpdate or :MasonToolsInstall.
      -- Default: false
      auto_update = true,
    })

    mason_nvim_dap.setup()

    -- language servers not installed with mason are configured in nvim-lspconfig
    mason_lspconfig.setup_handlers({
      -- default handler for installed servers
      function(server_name)
        lspconfig[server_name].setup({
          on_attach = on_attach,
          capabilities = capabilities,
        })
      end,
      ["svelte"] = function()
        -- configure svelte server
        lspconfig["svelte"].setup({
          capabilities = capabilities,
          on_attach = function(client, bufnr)
            vim.api.nvim_create_autocmd("BufWritePost", {
              pattern = { "*.js", "*.ts" },
              callback = function(ctx)
                -- Here use ctx.match instead of ctx.file
                client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
              end,
            })
          end,
          settings = {
            typescript = {
              inlayHints = {
                parameterNames = { enabled = "all" },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
              },
            },
          },
        })
      end,
      ["bashls"] = function()
        -- configure bash language server
        lspconfig["bashls"].setup({
          capabilities = capabilities,
          on_attach = on_attach,
          filetypes = { "sh", "bash" },
        })
      end,
      ["graphql"] = function()
        -- configure graphql language server
        lspconfig["graphql"].setup({
          capabilities = capabilities,
          on_attach = on_attach,
          filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
        })
      end,
      ["emmet_ls"] = function()
        -- configure emmet language server
        lspconfig["emmet_ls"].setup({
          capabilities = capabilities,
          on_attach = on_attach,
          filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
        })
      end,
      ["lua_ls"] = function()
        -- configure lua server (with special settings)
        lspconfig["lua_ls"].setup({
          capabilities = capabilities,
          on_attach = on_attach,
          settings = {
            Lua = {
              -- make the language server recognize "vim" global
              diagnostics = {
                globals = { "vim" },
              },
              completion = {
                callSnippet = "Replace",
              },
              hint = {
                enable = true,
              },
            },
          },
        })
      end,
      ["ts_ls"] = function()
        -- configure typescript server with plugin
        lspconfig["ts_ls"].setup({
          capabilities = capabilities,
          on_attach = on_attach,
          settings = {
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayVariableTypeHintsWhenTypeMatchesName = false,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayVariableTypeHintsWhenTypeMatchesName = false,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
          },
          --  settings = {
          --  implicitProjectConfiguration = {
          --  checkJs = true,
          --    },
          --  },
        })
      end,
      lspconfig.nixd.setup({
        capabilities = capabilities,
        on_attach = on_attach,
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
              darwin = {
                expr = '(builtins.getFlake ("git+file://" + toString ./.)).darwinConfigurations.mack.options',
              },
              -- nixd cannot get home-manager options when installed as a nix-darwin module
              -- ( See https://github.com/nix-community/nixd/issues/608 )
              -- home_manager = {
              --   expr = '(builtins.getFlake  "/Users/timotheos/.dotfiles").homeConfigurations."timotheos@mack".options',
              -- },
            },
          },
        },
      }),
      lspconfig.yamlls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
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
      }),
    })
  end,
}
