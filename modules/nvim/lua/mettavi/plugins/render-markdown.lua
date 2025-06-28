-- Plugin to improve viewing Markdown files in Neovim
return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = { latex = { enabled = false } },
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
}
