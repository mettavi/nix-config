return {
  "comment-nvim",
  auto_enable = true,
  event = { "BufReadPre", "BufNewFile" },
  -- on_plugin = "nvim-ts-context-commentstring",

  after = function(_)
    -- import comment plugin safely
    local comment = require("Comment")

    local ts_context_commentstring = require("ts_context_commentstring.integrations.comment_nvim")

    -- enable comment
    ---@diagnostic disable-next-line: missing-fields
    comment.setup({
      -- for commenting tsx, jsx, svelte, html files
      pre_hook = ts_context_commentstring.create_pre_hook(),
    })
  end,
}
