return {
  "bufferline.nvim",
  auto_enable = true,
  lazy = false,
  after = function(_)
    local bufferline = require("bufferline")
    bufferline.setup({
      options = {
        mode = "tabs",
        -- set this to to "thin" to prevent triangular white separators when setting tokyonight theme to transparent
        -- PS: this is the default
        separator_style = "thin",
        offsets = {
          {
            filetype = "NvimTree",
            text = "File Explorer",
            text_align = "center",
            separator = true,
          },
        },
      },
    })
  end,
}
