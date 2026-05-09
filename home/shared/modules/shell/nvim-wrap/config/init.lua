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
  { import = "mettavi.plugins.alpha" },
  { import = "mettavi.plugins.better-escape" },
  { import = "mettavi.plugins.colorscheme" },
  { import = "mettavi.plugins.autopairs" },
  { import = "mettavi.plugins.bufferline" },
  { import = "mettavi.plugins.comment" },
  { import = "mettavi.plugins.flash" },
  { import = "mettavi.plugins.formatting" },
  { import = "mettavi.plugins.gitsigns" },
  { import = "mettavi.plugins.indent-blankline" },
  { import = "mettavi.plugins.lazygit" },
  { import = "mettavi.plugins.linting" },
  { import = "mettavi.plugins.lsp.lspconfig" },
  { import = "mettavi.plugins.lsp.lsp-file-operations" },
  { import = "mettavi.plugins.lsp.bash_ls" },
  { import = "mettavi.plugins.lsp.lua_ls" },
  { import = "mettavi.plugins.lsp.nixd" },
  { import = "mettavi.plugins.lsp.ts_ls" },
  { import = "mettavi.plugins.lsp.yaml_ls" },
  { import = "mettavi.plugins.lualine" },
  { import = "mettavi.plugins.noice" },
  { import = "mettavi.plugins.nvim-tree" },
  { import = "mettavi.plugins.nvim-treesitter-text-objects" },
  { import = "mettavi.plugins.nvim-cmp" },
  { import = "mettavi.plugins.render-markdown" },
  { import = "mettavi.plugins.substitute" },
  { import = "mettavi.plugins.telescope" },
  { import = "mettavi.plugins.todo-comments" },
  { import = "mettavi.plugins.treesitter" },
  { import = "mettavi.plugins.ts-autotag" },
  { import = "mettavi.plugins.trouble" },
  { import = "mettavi.plugins.ts-context-commentstring" },
  { import = "mettavi.plugins.which-key" },
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
    "Schemastore.nvim",
    auto_enable = true,
    dep_of = "yaml-language-server",
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
  { "luasnip", auto_enable = true, dep_of = "nvim-cmp" },
  { "lspkind.nvim", auto_enable = true, on_plugin = "nvim-cmp" },
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
    "cmp-nvim-lsp",
    auto_enable = true,
    dep_of = { "nvim-lspconfig" },
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
    "nvim-surround",
    auto_enable = true,
    event = "DeferredUIEnter",
    -- keys = "",
    after = function(plugin)
      require("nvim-surround").setup()
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
    "taplo",
    lsp = {
      -- if you provide the filetypes it doesn't ask lspconfig for the filetypes
      -- (meaning it doesn't call the callback function we defined in the main init.lua)
      filetypes = { "toml" },
    },
  },
})
