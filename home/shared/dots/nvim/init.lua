require("mettavi.core")

-- NB: this just gives nixCats global command a default value
-- so that it doesnt throw an error if you didnt install via nix.
-- usage of both this setup and the nixCats command is optional,
-- but it is very useful for passing info from nix to lua so you will likely use it at least once.
require("nixCatsUtils").setup({
  non_nix_value = true,
})

-- NB: You might want to move the lazy-lock.json file
local function getlockfilepath()
  if require("nixCatsUtils").isNixCats and type(nixCats.settings.unwrappedCfgPath) == "string" then
    return nixCats.settings.unwrappedCfgPath .. "/lazy-lock.json"
  else
    return vim.fn.stdpath("config") .. "/lazy-lock.json"
  end
end
local lazyOptions = {
  lockfile = getlockfilepath(),
  checker = {
    enabled = true,
    notify = false,
  },
  change_detection = {
    notify = false,
  },
}

-- NB: this the lazy wrapper. Use it like require('lazy').setup() but with an extra
-- argument, the path to lazy.nvim as downloaded by nix, or nil, before the normal arguments.
require("nixCatsUtils.lazyCat").setup(nixCats.pawsible({ "allPlugins", "start", "lazy.nvim" }), {
  -- disable mason.nvim while using nix
  -- precompiled binaries do not agree with nixos, and we can just make nix install this stuff for us.
  { "williamboman/mason-lspconfig.nvim", enabled = require("nixCatsUtils").lazyAdd(true, false) },
  { "williamboman/mason.nvim", enabled = require("nixCatsUtils").lazyAdd(true, false) },
  {
    "nvim-treesitter/nvim-treesitter",
    build = require("nixCatsUtils").lazyAdd(":TSUpdate"),
    opts_extend = require("nixCatsUtils").lazyAdd(nil, false),
    opts = {
      -- nix already ensured they were installed, and we would need to change the parser_install_dir if we wanted to use it instead.
      -- so we just disable install and do it via nix.
      ensure_installed = require("nixCatsUtils").lazyAdd(
        { "bash", "c", "diff", "html", "lua", "luadoc", "markdown", "vim", "vimdoc" },
        false
      ),
      auto_install = require("nixCatsUtils").lazyAdd(true, false),
    },
  },
  {
    "folke/lazydev.nvim",
    opts = {
      library = {
        { path = (nixCats.nixCatsPath or "") .. "/lua", words = { "nixCats" } },
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  -- import/override with your plugins
  { import = "mettavi.plugins" },
  { import = "mettavi.plugins.lsp" },
}, lazyOptions)
