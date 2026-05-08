return {
  "conform.nvim",
  auto_enable = true,
  -- cmd = { "" },
  event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
  -- ft = "",
  keys = {
    { "<leader>mp", desc = "Format file or range (in visual mode)" },
  },
  -- colorscheme = "",
  after = function(plugin)
    local conform = require("conform")

    conform.setup({
      formatters_by_ft = {
        -- Conform will run multiple formatters sequentially
        -- python = { "isort", "black" },
        -- Use a sub-list to run only the first available formatter
        -- javascript = { { "prettierd", "prettier" } },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        svelte = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        yaml = { "yamlfmt" },
        markdown = { "prettier" },
        -- lua = { "stylua" },
        lua = nixInfo(nil, "settings", "cats", "lua") and { "stylua" } or nil,
        sh = { "shfmt" },
        toml = { "taplo" },
        nix = { "nixfmt" },
      },
      format_on_save = {
        lsp_format = "fallback",
        async = false,
        timeout_ms = 1000,
      },
    })

    vim.keymap.set({ "n", "v" }, "<leader>mp", function()
      conform.format({
        lsp_format = "fallback",
        async = false,
        timeout_ms = 1000,
      })
    end, { desc = "Format file or range (in visual mode)" })
  end,
}
