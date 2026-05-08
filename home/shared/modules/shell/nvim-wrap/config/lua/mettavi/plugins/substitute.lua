return {
  "substitute.nvim",
  auto_enable = true,
  event = { "BufReadPre", "BufNewFile" },
  after = function(_)
    local substitute = require("substitute")

    substitute.setup()

    -- set keymaps
    local keymap = vim.keymap -- for conciseness

    keymap.set("n", "<leader>r", substitute.operator, { desc = "Substitute with motion" })
    keymap.set("n", "<leader>rr", substitute.line, { desc = "Substitute line" })
    keymap.set("n", "<leader>R", substitute.eol, { desc = "Substitute to end of line" })
    keymap.set("x", "<leader>r", substitute.visual, { desc = "Substitute in visual mode" })
  end,
}
