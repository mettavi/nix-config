return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-tree/nvim-web-devicons",
    "folke/todo-comments.nvim",
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    local open_with_trouble = require("trouble.sources.telescope").open
    -- Use this to add more results without clearing the trouble list
    local add_to_trouble = require("trouble.sources.telescope").add

    telescope.setup({
      defaults = {
        path_display = { "smart" },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous, -- move to prev result
            ["<C-j>"] = actions.move_selection_next, -- move to next result
            ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist, -- for items selected with tab key
            ["<C-t>"] = open_with_trouble,
          },
          n = { ["<c-t>"] = open_with_trouble },
        },
      },
      pickers = {
        find_files = {
          hidden = true,
        },
        grep_string = {
          additional_args = { "--hidden" },
        },
        live_grep = {
          additional_args = { "--hidden" },
        },
      },
    })

    telescope.load_extension("fzf")

    -- set keymaps
    local keymap = vim.keymap -- for conciseness
    keymap.set("n", "<leader>ff", "<cmd>Telescope find_files follow=true<cr>", { desc = "Fuzzy find files in cwd" })
    keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" })
    keymap.set(
      "n",
      "<leader>fb",
      "<cmd>Telescope buffers sort_mru=true ignore_current_buffer=true<cr>",
      { desc = "Fuzzy find buffers" }
    )
    keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
    keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "Find string under cursor in cwd" })
    keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })
  end,
}
