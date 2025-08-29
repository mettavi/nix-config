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

    vim.lsp.enable("bashls")

    lspconfig("bashls", {
      capabilities = capabilities,
      on_attach = on_attach,
      filetypes = { "sh", "bash" },
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
