return {
  'mfussenegger/nvim-dap',
  event = 'VeryLazy',
  keys = {
    {
      '<leader>db',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = '[D]ebug Toggle [B]reakpoint',
    },
    {
      '<leader>dc',
      function()
        require('dap').continue()
      end,
      desc = '[D]ebug [C]ontinue',
    },
    {
      '<leader>do',
      function()
        require('dap').step_over()
      end,
      desc = '[D]ebug Step [O]ver',
    },
    {
      '<leader>di',
      function()
        require('dap').step_into()
      end,
      desc = '[D]ebug Step [I]nto',
    },
    {
      '<leader>du',
      function()
        require('dap').step_out()
      end,
      desc = '[D]ebug Step o[U]t',
    },
    {
      '<leader>dr',
      function()
        require('dap').repl.toggle()
      end,
      desc = '[D]ebug Toggle [R]EPL',
    },
    {
      '<leader>dt',
      function()
        require('dap').terminate()
      end,
      desc = '[D]ebug [T]erminate',
    },
  },

  config = function()
    local ok, dap = pcall(require, 'dap')
    if not ok then
      return
    end

    local mason_pkg = vim.fn.stdpath 'data' .. '/mason/packages/js-debug-adapter'
    local js_debug_server = vim.fn.glob(mason_pkg .. '/**/dapDebugServer.js', false, false)
    if js_debug_server == '' or vim.fn.filereadable(js_debug_server) == 0 then
      vim.notify('dap: js-debug-adapter not found.', vim.log.levels.WARN)
      return
    end
    dap.adapters['pwa-node'] = {
      type = 'server',
      host = '127.0.0.1',
      port = '${port}',
      executable = {
        command = 'node',
        args = { js_debug_server, '${port}' },
      },
    }

    local function get_dap_selection()
      local default_pattern = 'test/.*\\.spec\\.ts$'
      local test_pattern = vim.fn.input('Choose testPathPattern: ', default_pattern)

      local default_cwd = vim.fn.expand '%:p:h'
      local cwd = vim.fn.fnamemodify(vim.fn.input('Choose cwd: ', default_cwd, 'dir'), ':p')
      return { test_pattern = test_pattern, cwd = cwd }
    end

    local dap_selection_cache = nil
    local function get_cached_selection()
      if dap_selection_cache == nil then
        dap_selection_cache = get_dap_selection()
      end
      return dap_selection_cache
    end

    dap.listeners.after.event_terminated['clear_dap_selection'] = function()
      dap_selection_cache = nil
    end
    dap.listeners.after.event_exited['clear_dap_selection'] = function()
      dap_selection_cache = nil
    end

    dap.configurations.typescript = {
      {
        type = 'pwa-node',
        request = 'launch',
        name = 'Jest Tests',
        program = '${workspaceFolder}/node_modules/.bin/jest',
        args = function()
          return {
            '--rootDir=../..',
            '--no-cache',
            '--runInBand',
            '--testPathPatterns',
            get_cached_selection().test_pattern,
          }
        end,
        cwd = function()
          return get_cached_selection().cwd
        end,
        console = 'integratedTerminal',
        sourceMaps = true,
        protocol = 'inspector',
        env = {
          P8_AWS_REGION = 'us-east-1',
          P8_ENV_NAME = 'local',
        },
      },
    }
  end,
}
