return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require('harpoon')

    -- REQUIRED
    harpoon:setup()
    -- REQUIRED

    vim.keymap.set('n', '<leader>a', function()
      harpoon:list():add()
    end, { desc = 'Add file to harpoon' })
    vim.keymap.set('n', '<C-e>', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = 'Toggle harpoon quick menu' })

    vim.keymap.set('n', '<C-h>', function()
      harpoon:list():select(1)
    end, { desc = 'Select harpoon file 1' })
    vim.keymap.set('n', '<C-t>', function()
      harpoon:list():select(2)
    end, { desc = 'Select harpoon file 2' })
    vim.keymap.set('n', '<C-n>', function()
      harpoon:list():select(3)
    end, { desc = 'Select harpoon file 3' })
    vim.keymap.set('n', '<C-s>', function()
      harpoon:list():select(4)
    end, { desc = 'Select harpoon file 4' })
  end,
}