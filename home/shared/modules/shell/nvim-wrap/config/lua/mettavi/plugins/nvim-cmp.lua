return {
  "nvim-cmp",
  auto_enable = true,
  event = "InsertEnter",
  after = function(plugin)
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    local lspkind = require("lspkind")
    -- import nvim-autopairs completion functionality
    local cmp_autopairs = require("nvim-autopairs.completion.cmp")

    -- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
    require("luasnip.loaders.from_vscode").lazy_load()

    -- user-defined snippets
    require("luasnip.loaders.from_vscode").load_standalone({ path = "./my.code-snippets" })

    -- friendly-snippets - enable standardized comments snippets
    require("luasnip").filetype_extend("sh", { "shelldoc" })

    -- luasnip keybinds to interact with snippet nodes
    -- jump to next node
    vim.keymap.set({ "i", "s" }, "<Tab>", function()
      luasnip.jump(1)
    end, { silent = true })
    -- jump back to previous node
    vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
      luasnip.jump(-1)
    end, { silent = true })
    -- choose option at node
    vim.keymap.set({ "i", "s" }, "<C-E>", function()
      if luasnip.choice_active() then
        luasnip.change_choice(1)
      end
    end, { silent = true })

    -- add vim style up and down navigation to cmp-cmdline with ctrl-k and ctrl-j
    local cmdline_mappings = cmp.mapping.preset.cmdline({
      ["<C-j>"] = { c = cmp.mapping.select_next_item() },
      ["<C-k>"] = { c = cmp.mapping.select_prev_item() },
    })

    -- make autopairs and completion work together
    cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

    -- `/` cmdline setup.
    cmp.setup.cmdline("/", {
      mapping = cmdline_mappings,
      sources = {
        { name = "buffer" },
      },
    })

    -- `:` cmdline setup.
    cmp.setup.cmdline(":", {
      mapping = cmdline_mappings,
      sources = cmp.config.sources({
        { name = "path" },
      }, {
        {
          name = "cmdline",
          option = {
            ignore_cmds = { "Man", "!" },
          },
        },
      }),
    })

    cmp.setup({
      completion = {
        completeopt = "menu,menuone,preview,noselect",
      },
      snippet = { -- configure how nvim-cmp interacts with snippet engine
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-k>"] = cmp.mapping.select_prev_item(), -- previous suggestion
        ["<C-j>"] = cmp.mapping.select_next_item(), -- next suggestion
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
        ["<C-e>"] = cmp.mapping.abort(), -- close completion window
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
      }),
      -- sources for autocompletion
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" }, -- snippets
        { name = "buffer" }, -- text within current buffer
        { name = "path" }, -- file system paths
      }),
      -- configure lspkind for vs-code like pictograms in completion menu
      -- Suppress the warning: "Missing required fields in type `cmp.FormattingConfig`: `fields`, `expandable_indicator`"
      ---@diagnostic disable: missing-fields
      formatting = {
        format = lspkind.cmp_format({
          maxwidth = 50,
          ellipsis_char = "...",
        }),
      },
    })
  end,
}
