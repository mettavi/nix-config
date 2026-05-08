return {
  "indent-blankline.nvim",
  auto_enable = true,
  event = { "BufReadPre", "BufNewFile" },
  after = function()
    require("ibl").setup({ indent = { char = "┊" } })
  end,
}
