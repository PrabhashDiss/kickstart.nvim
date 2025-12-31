return {
  'toppair/peek.nvim',
  ft = 'markdown',
  build = 'deno task --quiet build:fast',
  config = function()
    local peek = require('peek')
    
    peek.setup {
      auto_load = true,
      close_on_bdelete = true,
      syntax = true,
      theme = 'dark',
      update_on_change = true,
      app = 'surf',
      filetype = { 'markdown' },
      throttle_at = 200000,
      throttle_time = 'auto',
    }

    -- Create user commands for peek
    vim.api.nvim_create_user_command('PeekOpen', peek.open, {})
    vim.api.nvim_create_user_command('PeekClose', peek.close, {})
  end,
}
