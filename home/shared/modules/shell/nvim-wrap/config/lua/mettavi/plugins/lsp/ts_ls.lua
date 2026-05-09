return {
  -- name of the lsp
  "ts_ls",
  -- provide a table containing filetypes,
  -- and then whatever your functions defined in the function type specs expect.
  -- in our case, it just expects the normal lspconfig setup options,
  -- but with a default on_attach and capabilities
  lsp = {
    -- if you provide the filetypes it doesn't ask lspconfig for the filetypes
    -- (meaning it doesn't call the callback function we defined in the main init.lua)
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    implicitProjectConfiguration = {
      checkJs = true,
    },
    settings = {
      typescript = {
        inlayHints = {
          includeInlayParameterNameHints = "all",
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayVariableTypeHintsWhenTypeMatchesName = false,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        },
      },
      javascript = {
        inlayHints = {
          includeInlayParameterNameHints = "all",
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayVariableTypeHintsWhenTypeMatchesName = false,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        },
      },
    },
  },
  -- also these are regular specs and you can use before and after and all the other normal fields
}
