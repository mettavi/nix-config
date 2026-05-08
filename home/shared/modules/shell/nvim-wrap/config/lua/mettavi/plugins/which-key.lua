return {
  "which-key.nvim",
  auto_enable = true,
  -- cmd = { "" },
  event = "DeferredUIEnter",
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },
  -- ft = "",
  -- colorscheme = "",
  before = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 500
  end,
  after = function()
    require("which-key").setup({})
    require("which-key").add({
      { "<leader><leader>", group = "buffer commands" },
      { "<leader><leader>_", hidden = true },
      { "<leader>c", group = "[c]ode" },
      { "<leader>c_", hidden = true },
      { "<leader>d", group = "[d]ocument" },
      { "<leader>d_", hidden = true },
      { "<leader>g", group = "[g]it" },
      { "<leader>g_", hidden = true },
      { "<leader>m", group = "[m]arkdown" },
      { "<leader>m_", hidden = true },
      { "<leader>r", group = "[r]ename" },
      { "<leader>r_", hidden = true },
      { "<leader>s", group = "[s]earch" },
      { "<leader>s_", hidden = true },
      { "<leader>t", group = "[t]oggles" },
      { "<leader>t_", hidden = true },
      { "<leader>w", group = "[w]orkspace" },
      { "<leader>w_", hidden = true },
    })
  end,
}
