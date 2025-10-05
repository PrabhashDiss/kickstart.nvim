-- Git integration plugin
return {
  'tpope/vim-fugitive',
  config = function()
    vim.keymap.set('n', '<leader>gs', vim.cmd.Git, { desc = 'Git status' })
    vim.keymap.set('n', '<leader>gc', ':Gcommit<CR>', { desc = 'Git commit' })
    vim.keymap.set('n', '<leader>gp', ':Gpush<CR>', { desc = 'Git push' })
    vim.keymap.set('n', '<leader>gl', ':Gpull<CR>', { desc = 'Git pull' })
    vim.keymap.set('n', '<leader>gb', ':Gblame<CR>', { desc = 'Git blame' })
  end,
}