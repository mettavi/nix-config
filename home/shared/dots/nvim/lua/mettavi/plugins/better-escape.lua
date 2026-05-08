return {
  "max397574/better-escape.nvim",
  config = function()
    require("better_escape").setup({
      timeout = vim.o.timeoutlen, -- after `timeout` passes, you can press the escape key and the plugin will ignore it
      default_mappings = true, -- setting this to false removes all the default mappings
      mappings = {
        -- i for insert, other modes are the first letter too
        i = {
          -- map kj to exit insert mode
          k = {
            j = "<Esc>",
          },
          -- map jk to exit insert mode
          j = {
            k = "<Esc>",
          },
        },
      },
    })
  end,
}
