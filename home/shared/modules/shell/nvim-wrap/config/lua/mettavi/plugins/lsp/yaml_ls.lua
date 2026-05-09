return {
  -- name of the lsp
  "yamlls",
  -- provide a table containing filetypes,
  -- and then whatever your functions defined in the function type specs expect.
  -- in our case, it just expects the normal lspconfig setup options,
  -- but with a default on_attach and capabilities
  lsp = {
    -- if you provide the filetypes it doesn't ask lspconfig for the filetypes
    -- (meaning it doesn't call the callback function we defined in the main init.lua)
    filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab", "yaml.helm-values" },
    settings = {
      yaml = {
        schemaStore = {
          -- must disable built-in schemaStore support if you want to use
          -- the neovim schemastore plugin and its advanced options like `ignore`.
          enable = false,
          -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
          url = "",
        },
        schemas = require("schemastore").yaml.schemas(),
        -- using yamlfmt for formatting
        format = {
          enable = false,
        },
      },
    },
  },
  -- also these are regular specs and you can use before and after and all the other normal fields
}
