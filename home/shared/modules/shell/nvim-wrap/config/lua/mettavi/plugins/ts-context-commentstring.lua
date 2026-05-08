return {
  "nvim-ts-context-commentstring",
  auto_enable = true,
  dep_of = "comment-nvim",

  after = function(_)
    require("ts_context_commentstring").setup()
  end,
}
