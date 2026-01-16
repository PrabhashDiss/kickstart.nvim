return {
  'stevearc/oil.nvim',
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {},
  dependencies = { { 'nvim-mini/mini.icons', opts = {} } },
  -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
  lazy = false,
  config = function()
    require('oil').setup()

    vim.keymap.set('n', '<leader>pv', '<CMD>Oil<CR>', { desc = '[P]arent [V]iew' })
  end,
}
