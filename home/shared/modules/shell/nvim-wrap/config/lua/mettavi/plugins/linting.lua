return {
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
}
