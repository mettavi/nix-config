-- set leader key to space
vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness

-- General Keymaps -------------------

keymap.set("n", "<C-s>", "<cmd>update<CR>", { desc = "Save current buffer" })
keymap.set("i", "<C-s>", "<Esc><cmd>update<CR>gi", { desc = "Save current buffer & return to insert mode" })

-- prevent the bad habit of using arrow keys
keymap.set({ "n", "i", "v" }, "<Left>", "<cmd>echoe 'Use h'<CR>")
keymap.set({ "n", "i", "v" }, "<Right>", "<cmd>echoe 'Use l'<CR>")
keymap.set({ "n", "i", "v" }, "<Up>", "<cmd>echoe 'Use k'<CR>")
keymap.set({ "n", "i", "v" }, "<Down>", "<cmd>echoe 'Use j'<CR>")

-- NB: The following 2 keymaps also need to to be set in nvim-treesitter-textobjects.lua
-- use ; without SHIFT to enter command line mode
keymap.set({ "n", "v" }, ";", ":", { desc = "Enter command line mode" })

-- use <leader>; after f/t to find the next occurrence
keymap.set({ "n", "v" }, "<leader>;", ";", { desc = "Find next occurrence in line" })

-- clear search highlights
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- delete single character without copying into register
keymap.set("n", "x", '"_x')

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

-- print the current file
keymap.set("n", "<leader>p", "<cmd>%w !lp<CR>", { desc = "Print file" })
