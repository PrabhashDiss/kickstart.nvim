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

    -- Create autogroup for peek autocommands
    local group = vim.api.nvim_create_augroup('PeekAutoOpen', { clear = true })

    -- Auto-open preview when entering markdown buffer
    vim.api.nvim_create_autocmd('BufEnter', {
      group = group,
      pattern = '*.md',
      callback = function()
        if vim.bo.filetype == 'markdown' then
          vim.schedule(function()
            peek.open()
          end)
        end
      end,
    })

    -- Auto-close preview when leaving markdown buffer
    vim.api.nvim_create_autocmd('BufLeave', {
      group = group,
      pattern = '*.md',
      callback = function()
        if peek.is_open() then
          peek.close()
        end
      end,
    })

    -- Auto-close preview when entering non-markdown buffers
    vim.api.nvim_create_autocmd({ 'BufEnter', 'FileType' }, {
      group = group,
      callback = function()
        local ft = vim.bo.filetype
        if (ft ~= 'markdown' and ft ~= '') or ft == 'netrw' or ft == 'dirvish' or ft == 'oil' then
          if peek.is_open() then
            peek.close()
          end
        end
      end,
    })
  end,
}
