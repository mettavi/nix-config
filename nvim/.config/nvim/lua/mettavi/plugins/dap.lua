local js_based_languages = {
  "typescript",
  "javascript",
}

return {
  { "nvim-neotest/nvim-nio" },
  {
    "theHamsta/nvim-dap-virtual-text",
    config = function()
      require("nvim-dap-virtual-text").setup({})
    end,
  },
  {
    "mfussenegger/nvim-dap",
    config = function()
      require("dapui").setup()

      local dap, dapui = require("dap"), require("dapui")

      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end
      vim.fn.sign_define(
        "DapBreakpoint",
        { text = "🔴", texthl = "DapBreakpoint", linehl = "DapBreakpoint", numhl = "DapBreakpoint" }
      )
      vim.keymap.set("n", "<Leader>dt", ":DapToggleBreakpoint<CR>")
      vim.keymap.set("n", "<Leader>dc", ":DapContinue<CR>")
      vim.keymap.set("n", "<Leader>dx", ":DapTerminate<CR>")
      vim.keymap.set("n", "<Leader>do", ":DapStepOver<CR>")
      -- vim.keymap.set("n", "<F5>", function()
      --   require("dap").continue()
      -- end)
      -- vim.keymap.set("n", "<F10>", function()
      --   require("dap").step_over()
      -- end)
      -- vim.keymap.set("n", "<F11>", function()
      --   require("dap").step_into()
      -- end)
      -- vim.keymap.set("n", "<F12>", function()
      --   require("dap").step_out()
      -- end)
      -- vim.keymap.set("n", "<Leader>b", function()
      --   require("dap").toggle_breakpoint()
      -- end)
      -- vim.keymap.set("n", "<Leader>B", function()
      --   require("dap").set_breakpoint()
      -- end)
      -- vim.keymap.set("n", "<Leader>lp", function()
      --   require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
      -- end)
      -- vim.keymap.set("n", "<Leader>dr", function()
      --   require("dap").repl.open()
      -- end)
      -- vim.keymap.set("n", "<Leader>dl", function()
      --   require("dap").run_last()
      -- end)
      -- vim.keymap.set({ "n", "v" }, "<Leader>dh", function()
      --   require("dap.ui.widgets").hover()
      -- end)
      -- vim.keymap.set({ "n", "v" }, "<Leader>dp", function()
      --   require("dap.ui.widgets").preview()
      -- end)
      -- vim.keymap.set("n", "<Leader>df", function()
      --   local widgets = require("dap.ui.widgets")
      --   widgets.centered_float(widgets.frames)
      -- end)
      -- vim.keymap.set("n", "<Leader>ds", function()
      --   local widgets = require("dap.ui.widgets")
      --   widgets.centered_float(widgets.scopes)
      -- end)

      for _, language in ipairs(js_based_languages) do
        dap.configurations[language] = {
          -- Debug single nodejs files
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file",
            program = "${file}",
            cwd = vim.fn.getcwd(),
            sourceMaps = true,
          },
          -- Debug nodejs processes (make sure to add --inspect when you run the process)
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach",
            processId = require("dap.utils").pick_process,
            cwd = vim.fn.getcwd(),
            sourceMaps = true,
          },
          -- Debug web applications (client side)
          {
            type = "pwa-chrome",
            request = "launch",
            name = "Launch & Debug Chrome",
            url = function()
              local co = coroutine.running()
              return coroutine.create(function()
                vim.ui.input({
                  prompt = "Enter URL: ",
                  default = "http://localhost:3000",
                }, function(url)
                  if url == nil or url == "" then
                    return
                  else
                    coroutine.resume(co, url)
                  end
                end)
              end)
            end,
            webRoot = vim.fn.getcwd(),
            protocol = "inspector",
            sourceMaps = true,
            userDataDir = false,
          },
        }
      end
    end,
    dependencies = {
      -- Install the vscode-js-debug adapter
      {
        "microsoft/vscode-js-debug",
        -- After install, build it and rename the dist directory to out
        build = "npm install --legacy-peer-deps --no-save && npx gulp vsDebugServerBundle && rm -rf out && mv dist out",
        version = "1.*",
      },
      "rcarriga/nvim-dap-ui",
      {
        "mxsdev/nvim-dap-vscode-js",
        config = function()
          ---@diagnostic disable-next-line: missing-fields
          require("dap-vscode-js").setup({
            -- Path of node executable. Defaults to $NODE_PATH, and then "node"
            -- node_path = "node",

            -- Path to vscode-js-debug installation.
            debugger_path = vim.fn.resolve(vim.fn.stdpath("data") .. "/lazy/vscode-js-debug"),

            -- Command to use to launch the debug server. Takes precedence over "node_path" and "debugger_path"
            -- debugger_cmd = { "js-debug-adapter" },

            -- which adapters to register in nvim-dap
            adapters = {
              "pwa-node",
              "pwa-chrome",
              "pwa-msedge",
              "pwa-extensionHost",
              "node-terminal",
            },

            -- Path for file logging
            -- log_file_path = "(stdpath cache)/dap_vscode_js.log",

            -- Logging level for output to file. Set to false to disable logging.
            -- log_file_level = false,

            -- Logging level for output to console. Set to false to disable console output.
            -- log_console_level = vim.log.levels.ERROR,
          })
        end,
      },
    },
  },
}
