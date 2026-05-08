return {
  "todo-comments.nvim",
  auto_enable = true,
  event = { "BufReadPre", "BufNewFile" },
  after = function()
    local todo_comments = require("todo-comments")

    todo_comments.setup()

    -- set keymaps
    local keymap = vim.keymap -- for conciseness

    keymap.set("n", "]t", function()
      todo_comments.jump_next()
    end, { desc = "Next todo comment" })

    keymap.set("n", "[t", function()
      todo_comments.jump_prev()
    end, { desc = "Previous todo comment" })
  end,
}
