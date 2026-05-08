-- Plugin to improve viewing Markdown files in Neovim
return {
  "render-markdown.nvim",
  auto_enable = true,
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  ft = { "markdown", "quarto" },
  after = function(_)
    require("render-markdown").setup({
      -- add markdown completions
      completions = { lsp = { enabled = true } },
      latex = { enabled = false },
    })
  end,
}
