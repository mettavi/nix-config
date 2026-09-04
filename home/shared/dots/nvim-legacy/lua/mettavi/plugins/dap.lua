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
      vim.fn.sign_define(
        "DapLogPoint",
        { text = "🗨️", texthl = "DapLogPoint", linehl = "DapLogPoint", numhl = "DapLogPoint" }
      ) --🗨️🗯️
      vim.fn.sign_define(
        "DapBreakpointRejected",
        { text = "⛔", texthl = "DapBreakpoint", linehl = "DapBreakpoint", numhl = "DapBreakpoint" }
      )
      vim.fn.sign_define(
        "DapBreakpointCondition",
        { text = "🟡", texthl = "blue", linehl = "DapBreakpoint", numhl = "DapBreakpoint" }
      )
      vim.fn.sign_define(
        "DapStopped",
        { text = "👽", texthl = "DapStopped", linehl = "DapStopped", numhl = "DapStopped" }
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

      dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "node",
          -- 💀 Make sure to update this path to point to your installation
          args = { vim.fn.stdpath("data") .. "/lazy/vscode-js-debug/src/dapDebugServer.js", "${port}" },
        },
      }

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
        version = "1.x",
        build = "npm install --legacy-peer-deps && npm run compile dapDebugServer && mv dist out",
      },
      "rcarriga/nvim-dap-ui",
    },
  },
}
