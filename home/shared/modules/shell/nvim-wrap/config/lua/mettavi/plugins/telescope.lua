return {
  "telescope.nvim",
  auto_enable = true,
  lazy = false,
  after = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    -- local open_with_trouble = require("trouble.sources.telescope").open
    -- Use this to add more results without clearing the trouble list
    -- local add_to_trouble = require("trouble.sources.telescope").add

    -- setup telescope
    telescope.setup({
      defaults = {
        path_display = { "smart" },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous, -- move to prev result
            ["<C-j>"] = actions.move_selection_next, -- move to next result
            ["<S-C-q>"] = actions.send_selected_to_qflist + actions.open_qflist, -- for items selected with tab key
            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist, -- for all items found
            -- ["<C-t>"] = open_with_trouble,
          },
          -- n = { ["<c-t>"] = open_with_trouble },
        },
      },
      extensions = {
        fzf = {
          fuzzy = true, -- false will only do exact matching
          override_generic_sorter = true, -- override the generic sorter
          override_file_sorter = true, -- override the file sorter
          case_mode = "smart_case", -- or "ignore_case" or "respect_case"
          -- the default case_mode is "smart_case"
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
          -- search hidden files, except those in .git
          glob_pattern = { "!.git" },
          additional_args = { "--hidden" },
        },
      },
    })

    -- load telescope extensions
    -- telescope.load_extension("lazygit")
    -- telescope.load_extension("fzf")
    -- telescope.load_extension("noice")

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
    keymap.set("n", "<leader>fk", "<cmd>Telescope keymaps<cr>", { desc = "Find keymaps" })
  end,
}
