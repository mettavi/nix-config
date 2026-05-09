return {
  "nvim-lspconfig",
  auto_enable = true,
  -- NOTE: define a function for lsp,
  -- and it will run for all specs with type(plugin.lsp) == table
  -- when their filetype trigger loads them
  lsp = function(plugin)
    vim.lsp.config(plugin.name, plugin.lsp or {})
    vim.lsp.enable(plugin.name)
  end,

  -- set up our on_attach function once before the spec loads
  before = function(_)
    vim.lsp.config("*", {
      on_attach = function(_, bufnr)
        -- we create a function that lets us more easily define mappings specific
        -- for LSP related items. It sets the mode, buffer and description for us each time.
        local nmap = function(keys, func, desc)
          if desc then
            desc = "LSP: " .. desc
          end
          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
        end

        nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
        nmap("<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", "[D]iagnostics for buffer")
        nmap("<leader>dl", vim.diagnostic.open_float, "[d]iagnostics for line")
        nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
        nmap("gt", vim.lsp.buf.type_definition, "Type [D]efinition")

        -- See `:help K` for why this keymap
        nmap("K", vim.lsp.buf.hover, "Hover Documentation")
        nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")

        -- Lesser used LSP functionality
        nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
        nmap("<leader>rs", ":LspRestart<CR>", "[R]e[s]tart LSP")
        nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
        nmap("gR", "<cmd>Telescope lsp_references<CR>", "[G]oto LSP [R]eferences")
        nmap("gd", "<cmd>Telescope lsp_definitions<CR>", "[G]oto LSP [d]efinitions")
        nmap("gi", "<cmd>Telescope lsp_implementations<CR>", "[G]oto LSP [i]mplementations")
        nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
        nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
        nmap("<leader>wl", function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, "[W]orkspace [L]ist Folders")

        -- Create a command `:Format` local to the LSP buffer
        vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
          vim.lsp.buf.format()
        end, { desc = "Format current buffer with LSP" })
      end,
    })
  end,
  after = function()
    -- import cmp-nvim-lsp plugin
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    -- enable autocompletion via nvim-cmp (assign to every lsp server config)
    -- by extending the capabilities of lsp/neovim with nvim-cmp
    local capabilities = cmp_nvim_lsp.default_capabilities()

    vim.lsp.config("*", {
      capabilities = capabilities,
    })

    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        -- enable (and toggle) inlay hints with a command or keymap
        local bufnr = args.buf ---@type number
        local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
        if client.server_capabilities.inlayHintProvider then
          vim.api.nvim_create_user_command("ToggleInlayHints", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
          end, { desc = "Toggle Inlay Hints" })
          vim.keymap.set("n", "<leader>i", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
            vim.notify("Inlay hints: " .. ((vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })) and " on" or "off"))
          end, { buffer = bufnr, desc = "Toggle Inlay Hints" })
        else
          print("no inlay hints available")
        end
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
