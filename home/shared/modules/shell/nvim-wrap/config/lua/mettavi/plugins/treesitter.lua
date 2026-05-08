return {
  "nvim-treesitter",
  lazy = false,
  auto_enable = true,
  after = function()
    ---@param buf integer
    ---@param language string

    local languages = {
      "json",
      "javascript",
      "typescript",
      "tsx",
      "yaml",
      "html",
      "css",
      "markdown",
      "markdown_inline",
      "svelte",
      "bash",
      "lua",
      "vim",
      "dockerfile",
      "gitignore",
      "query",
      "vimdoc",
      "c",
      "toml",
      "regex",
      "nix",
    }
    -- replicate `ensure_installed`, runs asynchronously, skips existing languages
    require("nvim-treesitter").install(languages)

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
}
