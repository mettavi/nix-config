-- The first 100ish lines are setup,
-- the rest is usage of lze and various core plugins!

vim.loader.enable() -- <- bytecode caching
do
  -- Set up a global in a way that also handles non-nix compat
  local ok
  ok, _G.nixInfo = pcall(require, vim.g.nix_info_plugin_name)
  if not ok then
    package.loaded[vim.g.nix_info_plugin_name] = setmetatable({}, {
      __call = function(_, default)
        return default
      end,
    })
    _G.nixInfo = require(vim.g.nix_info_plugin_name)
    -- If you always use the fetcher function to fetch nix values,
    -- rather than indexing into the tables directly,
    -- it will use the value you specified as the default
  end

  nixInfo.isNix = vim.g.nix_info_plugin_name ~= nil
  ---@module 'lzextras'
  ---@type lzextras | lze
  nixInfo.lze = setmetatable(require("lze"), getmetatable(require("lzextras")))
  function nixInfo.get_nix_plugin_path(name)
    return nixInfo(nil, "plugins", "lazy", name) or nixInfo(nil, "plugins", "start", name)
  end
end

nixInfo.lze.register_handlers({
  {
    -- adds an `auto_enable` field to lze specs
    -- if true, will disable it if not installed by nix.
    -- if string, will disable if that name was not installed by nix.
    -- if a table of strings, it will disable if any were not.
    spec_field = "auto_enable",
    set_lazy = false,
    modify = function(plugin)
      if vim.g.nix_info_plugin_name then
        if type(plugin.auto_enable) == "table" then
          for _, name in pairs(plugin.auto_enable) do
            if not nixInfo.get_nix_plugin_path(name) then
              plugin.enabled = false
              break
            end
          end
        elseif type(plugin.auto_enable) == "string" then
          if not nixInfo.get_nix_plugin_path(plugin.auto_enable) then
            plugin.enabled = false
          end
        elseif type(plugin.auto_enable) == "boolean" and plugin.auto_enable then
          if not nixInfo.get_nix_plugin_path(plugin.name) then
            plugin.enabled = false
          end
        end
      end
      return plugin
    end,
  },
  {
    -- we made an options.settings.cats with the value of enable for our top level specs
    -- give for_cat = "name" to disable if that one is not enabled
    spec_field = "for_cat",
    set_lazy = false,
    modify = function(plugin)
      if vim.g.nix_info_plugin_name then
        if type(plugin.for_cat) == "string" then
          plugin.enabled = nixInfo(false, "settings", "cats", plugin.for_cat)
        end
      end
      return plugin
    end,
  },
  -- From lzextras. This one makes it so that
  -- you can set up lsps within lze specs,
  -- and trigger lspconfig setup hooks only on the correct filetypes
  -- It is (unfortunately) important that it be registered after the above 2,
  -- as it also relies on the modify hook, and the value of enabled at that point
  nixInfo.lze.lsp,
})

-- NOTE: This config uses lzextras.lsp handler https://github.com/BirdeeHub/lzextras?tab=readme-ov-file#lsp-handler
-- Because we have the paths, we can set a more performant fallback function
-- for when you don't provide a filetype to trigger on yourself.
-- If you do provide a filetype, this will never be called.
nixInfo.lze.h.lsp.set_ft_fallback(function(name)
  local lspcfg = nixInfo.get_nix_plugin_path("nvim-lspconfig")
  if lspcfg then
    local ok, cfg = pcall(dofile, lspcfg .. "/lsp/" .. name .. ".lua")
    return (ok and cfg or {}).filetypes or {}
  else
    -- the less performant thing we are trying to avoid at startup
    return (vim.lsp.config[name] or {}).filetypes or {}
  end
end)

-- NOTE: You will likely want to break this up into more files.
-- You can call this more than once.
-- You can also include other files from within the specs via an `import` spec.
-- see https://github.com/BirdeeHub/lze?tab=readme-ov-file#structuring-your-plugins

require("mettavi.core")

nixInfo.lze.load({
  -- { require("lze").load("mettavi.plugins") },
  { import = "mettavi.plugins.colorscheme" },
  { import = "mettavi.plugins.autopairs" },
  { import = "mettavi.plugins.comment" },
  { import = "mettavi.plugins.flash" },
  { import = "mettavi.plugins.indent-blankline" },
  { import = "mettavi.plugins.lazygit" },
  { import = "mettavi.plugins.noice" },
  { import = "mettavi.plugins.nvim-tree" },
  { import = "mettavi.plugins.render-markdown" },
  { import = "mettavi.plugins.substitute" },
  { import = "mettavi.plugins.telescope" },
  { import = "mettavi.plugins.todo-comments" },
  { import = "mettavi.plugins.trouble" },
  { import = "mettavi.plugins.ts-context-commentstring" },
  {
    "auto-session",
    auto_enable = true,
    after = function(plugin)
      require("auto-session").setup({})
    end,
  },
  {
    "nvim-notify",
    auto_enable = true,
    dep_of = "noice.nvim",
    after = function(plugin)
      require("notify").setup()
    end,
  },
  {
    "nui.nvim",
    auto_enable = true,
    dep_of = "noice.nvim",
  },
  {
    "telescope-fzf-native.nvim",
    auto_enable = true,
    on_plugin = "telescope.nvim",
    after = function(plugin)
      require("telescope").load_extension("fzf")
    end,
  },
  {
    "vim-maximizer",
    keys = {
      { "<leader>sm", "<cmd>MaximizerToggle<CR>", desc = "Maximize/minimize a split" },
    },
  },
  {
    "better-escape.nvim",
    auto_enable = true,
    after = function(plugin)
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
  },
  {
    "conform.nvim",
    auto_enable = true,
    -- cmd = { "" },
    event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
    -- ft = "",
    keys = {
      { "<leader>mp", desc = "Format file or range (in visual mode)" },
    },
    -- colorscheme = "",
    after = function(plugin)
      local conform = require("conform")

      conform.setup({
        formatters_by_ft = {
          -- Conform will run multiple formatters sequentially
          -- python = { "isort", "black" },
          -- Use a sub-list to run only the first available formatter
          -- javascript = { { "prettierd", "prettier" } },
          javascript = { "prettier" },
          typescript = { "prettier" },
          javascriptreact = { "prettier" },
          typescriptreact = { "prettier" },
          svelte = { "prettier" },
          css = { "prettier" },
          html = { "prettier" },
          json = { "prettier" },
          yaml = { "yamlfmt" },
          markdown = { "prettier" },
          -- lua = { "stylua" },
          lua = nixInfo(nil, "settings", "cats", "lua") and { "stylua" } or nil,
          sh = { "shfmt" },
          toml = { "taplo" },
          nix = { "nixfmt" },
        },
        format_on_save = {
          lsp_format = "fallback",
          async = false,
          timeout_ms = 1000,
        },
      })

      vim.keymap.set({ "n", "v" }, "<leader>mp", function()
        conform.format({
          lsp_format = "fallback",
          async = false,
          timeout_ms = 1000,
        })
      end, { desc = "Format file or range (in visual mode)" })
    end,
  },
  {
    "gitsigns.nvim",
    auto_enable = true,
    event = { "BufReadPre", "BufNewFile" },
    -- cmd = { "" },
    -- ft = "",
    -- keys = "",
    -- colorscheme = "",
    after = function(plugin)
      require("gitsigns").setup({
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, desc)
            vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
          end

          -- Navigation
          map("n", "]h", gs.next_hunk, "Next Hunk")
          map("n", "[h", gs.prev_hunk, "Prev Hunk")

          -- Actions
          map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
          map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
          map("v", "<leader>hs", function()
            gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end, "Stage hunk")
          map("v", "<leader>hr", function()
            gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end, "Reset hunk")

          map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
          map("n", "<leader>hR", gs.reset_buffer, "Reset buffer")

          map("n", "<leader>hu", gs.undo_stage_hunk, "Undo stage hunk")

          map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")

          map("n", "<leader>hb", function()
            gs.blame_line({ full = true })
          end, "Blame line")
          map("n", "<leader>hB", gs.toggle_current_line_blame, "Toggle line blame")

          map("n", "<leader>hd", gs.diffthis, "Diff this")
          map("n", "<leader>hD", function()
            gs.diffthis("~")
          end, "Diff this ~")

          -- Text object
          map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Gitsigns select hunk")
        end,
      })
    end,
  },
  {
    -- lazydev makes your lua lsp load only the relevant definitions for a file.
    -- It also gives us a nice way to correlate globals we create with files.
    "lazydev.nvim",
    auto_enable = true,
    cmd = { "LazyDev" },
    ft = "lua",
    after = function(_)
      require("lazydev").setup({
        library = {
          { words = { "nixInfo%.lze" }, path = nixInfo("lze", "plugins", "start", "lze") .. "/lua" },
          { words = { "nixInfo%.lze" }, path = nixInfo("lzextras", "plugins", "start", "lzextras") .. "/lua" },
        },
      })
    end,
  },
  {
    -- name of the lsp
    "lua_ls",
    for_cat = "lua",
    -- provide a table containing filetypes,
    -- and then whatever your functions defined in the function type specs expect.
    -- in our case, it just expects the normal lspconfig setup options,
    -- but with a default on_attach and capabilities
    lsp = {
      -- if you provide the filetypes it doesn't ask lspconfig for the filetypes
      -- (meaning it doesn't call the callback function we defined in the main init.lua)
      filetypes = { "lua" },
      settings = {
        Lua = {
          signatureHelp = { enabled = true },
          diagnostics = {
            globals = { "nixInfo", "vim" },
            disable = { "missing-fields" },
          },
        },
      },
    },
    -- also these are regular specs and you can use before and after and all the other normal fields
  },
  {
    "lualine.nvim",
    auto_enable = true,
    -- cmd = { "" },
    event = "DeferredUIEnter",
    -- ft = "",
    -- keys = "",
    -- colorscheme = "",
    after = function(plugin)
      local lualine = require("lualine")

      local colors = {
        blue = "#65D1FF",
        green = "#3EFFDC",
        violet = "#FF61EF",
        yellow = "#FFDA7B",
        red = "#FF4A4A",
        fg = "#c3ccdc",
        bg = "#112638",
        inactive_bg = "#2c3043",
      }

      local bgtrans = nil
      if vim.env.ITERM_SESSION_ID ~= nil then
        bgtrans = colors.none
      else
        bgtrans = colors.bg
      end

      local my_lualine_theme = {
        normal = {
          a = { bg = colors.blue, fg = colors.bg, gui = "bold" },
          b = { bg = colors.bg, fg = colors.fg },
          c = { bg = bgtrans, fg = colors.fg },
        },
        insert = {
          a = { bg = colors.green, fg = colors.bg, gui = "bold" },
          b = { bg = colors.bg, fg = colors.fg },
          c = { bg = bgtrans, fg = colors.fg },
        },
        visual = {
          a = { bg = colors.violet, fg = colors.bg, gui = "bold" },
          b = { bg = colors.bg, fg = colors.fg },
          c = { bg = bgtrans, fg = colors.fg },
        },
        command = {
          a = { bg = colors.yellow, fg = colors.bg, gui = "bold" },
          b = { bg = colors.bg, fg = colors.fg },
          c = { bg = bgtrans, fg = colors.fg },
        },
        replace = {
          a = { bg = colors.red, fg = colors.bg, gui = "bold" },
          b = { bg = colors.bg, fg = colors.fg },
          c = { bg = bgtrans, fg = colors.fg },
        },
        inactive = {
          a = { bg = colors.inactive_bg, fg = colors.semilightgray, gui = "bold" },
          b = { bg = colors.inactive_bg, fg = colors.semilightgray },
          c = { bg = bgtrans, fg = colors.semilightgray },
        },
      }

      require("lualine").setup({
        options = {
          theme = my_lualine_theme,
          component_separators = "|",
          section_separators = "",
        },
        sections = {
          lualine_c = {
            { "filename", path = 1, status = true },
          },
        },
        inactive_sections = {
          lualine_b = {
            { "filename", path = 3, status = true },
          },
          lualine_x = { "filetype" },
        },
        tabline = {
          lualine_a = { "buffers" },
          -- if you use lualine-lsp-progress, I have mine here instead of fidget
          -- lualine_b = { 'lsp_progress', },
          lualine_z = { "tabs" },
        },
      })
    end,
  },
  { "luasnip", auto_enable = true, dep_of = "nvim-cmp" },
  { "lspkind.nvim", auto_enable = true, on_plugin = "nvim-cmp" },
  {
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
  },
  {
    "cmp-buffer",
    auto_enable = true,
    on_plugin = { "nvim-cmp" },
    load = nixInfo.lze.loaders.with_after,
  },
  {
    "cmp-cmdline",
    auto_enable = true,
    on_plugin = { "nvim-cmp" },
    load = nixInfo.lze.loaders.with_after,
  },
  {
    "cmp-path",
    auto_enable = true,
    on_plugin = { "nvim-cmp" },
    load = nixInfo.lze.loaders.with_after,
  },
  {
    "cmp_luansip",
    auto_enable = true,
    on_plugin = { "nvim-cmp" },
    load = nixInfo.lze.loaders.with_after,
  },
  {
    "friendly-snippets",
    auto_enable = true,
    dep_of = { "nvim-cmp" },
  },
  {
    "nvim-lspconfig",
    auto_enable = true,
    -- NOTE: define a function for lsp,
    -- and it will run for all specs with type(plugin.lsp) == table
    -- when their filetype trigger loads them
    lsp = function(plugin)
      vim.lsp.config(plugin.name, plugin.lsp or {})
      vim.lsp.enable(plugin.name)
    end,
    -- set up our on_attach function once before the spec loads
    before = function(_)
      vim.lsp.config("*", {
        on_attach = function(_, bufnr)
          -- we create a function that lets us more easily define mappings specific
          -- for LSP related items. It sets the mode, buffer and description for us each time.
          local nmap = function(keys, func, desc)
            if desc then
              desc = "LSP: " .. desc
            end
            vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
          end

          nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
          nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
          nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
          nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")

          -- See `:help K` for why this keymap
          nmap("K", vim.lsp.buf.hover, "Hover Documentation")
          nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")

          -- Lesser used LSP functionality
          nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
          nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
          nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
          nmap("<leader>wl", function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, "[W]orkspace [L]ist Folders")

          -- Create a command `:Format` local to the LSP buffer
          vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
            vim.lsp.buf.format()
          end, { desc = "Format current buffer with LSP" })
        end,
      })
    end,
  },
  {
    "nixd",
    enabled = nixInfo.isNix, -- mason doesn't have nixd
    for_cat = "nix",
    lsp = {
      filetypes = { "nix" },
      settings = {
        nixd = {
          nixpkgs = {
            expr = [[import <nixpkgs> {}]],
          },
          options = {},
          formatting = {
            command = { "nixfmt" },
          },
          diagnostic = {
            suppress = {
              "sema-escaping-with",
            },
          },
        },
      },
    },
  },
  {
    "nvim-lint",
    auto_enable = true,
    -- cmd = { "" },
    event = "FileType",
    -- ft = "",
    -- keys = "",
    -- colorscheme = "",
    after = function(plugin)
      local lint = require("lint")
      lint.linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        svelte = { "eslint_d" },
        python = { "pylint" },
        nix = { "nix" },
        yaml = { "yamllint" },
      }

      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
        group = lint_augroup,
        callback = function()
          lint.try_lint()
        end,
      })

      vim.keymap.set("n", "<leader>lf", function()
        lint.try_lint()
      end, { desc = "Trigger linting for current file" })
    end,
  },
  {
    "nvim-surround",
    auto_enable = true,
    event = "DeferredUIEnter",
    -- keys = "",
    after = function(plugin)
      require("nvim-surround").setup()
    end,
  },
  {
    "nvim-treesitter",
    lazy = false,
    auto_enable = true,
    after = function(plugin)
      ---@param buf integer
      ---@param language string
      local function treesitter_try_attach(buf, language)
        -- check if parser exists and load it
        if not vim.treesitter.language.add(language) then
          return false
        end
        -- enables syntax highlighting and other treesitter features
        vim.treesitter.start(buf, language)

        -- enables treesitter based folds
        vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.wo.foldmethod = "expr"
        -- ensure folds are open to begin with
        vim.o.foldlevel = 99

        -- enables treesitter based indentation
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

        return true
      end

      local installable_parsers = require("nvim-treesitter").get_available()
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local buf, filetype = args.buf, args.match
          local language = vim.treesitter.language.get_lang(filetype)
          if not language then
            return
          end

          if not treesitter_try_attach(buf, language) then
            if vim.tbl_contains(installable_parsers, language) then
              -- not already installed, so try to install them via nvim-treesitter if possible
              require("nvim-treesitter").install(language):await(function()
                treesitter_try_attach(buf, language)
              end)
            end
          end
        end,
      })
    end,
  },
  {
    "nvim-treesitter-textobjects",
    auto_enable = true,
    lazy = false,
    before = function(plugin)
      -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects/tree/main?tab=readme-ov-file#using-a-package-manager
      -- Disable entire built-in ftplugin mappings to avoid conflicts.
      -- See https://github.com/neovim/neovim/tree/master/runtime/ftplugin for built-in ftplugins.
      vim.g.no_plugin_maps = true

      -- Or, disable per filetype (add as you like)
      -- vim.g.no_python_maps = true
      -- vim.g.no_ruby_maps = true
      -- vim.g.no_rust_maps = true
      -- vim.g.no_go_maps = true
    end,
    after = function(plugin)
      require("nvim-treesitter-textobjects").setup({
        select = {
          -- Automatically jump forward to textobj, similar to targets.vim
          lookahead = true,
          -- You can choose the select mode (default is charwise 'v')
          --
          -- Can also be a function which gets passed a table with the keys
          -- * query_string: eg '@function.inner'
          -- * method: eg 'v' or 'o'
          -- and should return the mode ('v', 'V', or '<c-v>') or a table
          -- mapping query_strings to modes.
          selection_modes = {
            ["@parameter.outer"] = "v", -- charwise
            ["@function.outer"] = "V", -- linewise
            -- ['@class.outer'] = '<c-v>', -- blockwise
          },
          -- If you set this to `true` (default is `false`) then any textobject is
          -- extended to include preceding or succeeding whitespace. Succeeding
          -- whitespace has priority in order to act similarly to eg the built-in
          -- `ap`.
          --
          -- Can also be a function which gets passed a table with the keys
          -- * query_string: eg '@function.inner'
          -- * selection_mode: eg 'v'
          -- and should return true of false
          include_surrounding_whitespace = false,
        },
      })

      -- keymaps
      -- You can use the capture groups defined in `textobjects.scm`
      vim.keymap.set({ "x", "o" }, "am", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
      end)
      vim.keymap.set({ "x", "o" }, "im", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
      end)
      vim.keymap.set({ "x", "o" }, "ac", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects")
      end)
      vim.keymap.set({ "x", "o" }, "ic", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects")
      end)
      -- You can also use captures from other query groups like `locals.scm`
      vim.keymap.set({ "x", "o" }, "as", function()
        require("nvim-treesitter-textobjects.select").select_textobject("@local.scope", "locals")
      end)

      -- NOTE: for more textobjects options, see the following link.
      -- This template is using the new `main` branch of the repo.
      -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects/tree/main
    end,
  },
  {
    "nvim-web-devicons",
    auto_enable = true,
    after = function(plugin)
      require("nvim-web-devicons").setup()
    end,
  },
  {
    "which-key.nvim",
    auto_enable = true,
    -- cmd = { "" },
    event = "DeferredUIEnter",
    -- ft = "",
    -- keys = "",
    -- colorscheme = "",
    after = function(plugin)
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
  },
})
