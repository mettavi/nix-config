return {
  "flash.nvim",
  auto_enable = true,
  event = "DeferredUIEnter",
  after = function()
    ---@type Flash.Config
    vim.keymap.set({ "n", "x", "o" }, "s", function()
      require("flash").jump()
    end, { noremap = true, silent = true, desc = "Yank to clipboard" })

    vim.keymap.set({ "n", "x", "o" }, "S", function()
      require("flash").treesitter()
    end, { desc = "Flash treesitter" })

    vim.keymap.set({ "o" }, "<leader>s", function()
      require("flash").remote()
    end, { desc = "Flash remote" })

    vim.keymap.set({ "o", "x" }, "<leader>S", function()
      require("flash").treesitter_search()
    end, { desc = "Flash treesitter remote" })

    vim.keymap.set({ "c" }, "<S>s", function()
      require("flash").toggle()
    end, { desc = "Toggle flash search" })

    require("flash").setup({
      modes = {
        search = {
          -- use flash in search mode (/ or ?) by default
          enabled = true,
        },
        char = {
          -- add labels when using f/F and t/T
          jump_labels = true,
        },
      },
    })
  end,
}
