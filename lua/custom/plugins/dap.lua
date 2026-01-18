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
  end,
}
