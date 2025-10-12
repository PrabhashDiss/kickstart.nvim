-- Neogit plugin configuration
return {
  'NeogitOrg/neogit',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'sindrets/diffview.nvim',
    'nvim-telescope/telescope.nvim',
  },
  opts = {
    integrations = {
      telescope = true,
      diffview = true,
    },
  },
  config = function(_, opts)
    require('neogit').setup(opts)

    -- Neogit keymaps
    vim.keymap.set('n', '<leader>gc', function()
      require('neogit').open { 'commit' }
    end, { desc = '[G]it [C]ommit' })
    vim.keymap.set('n', '<leader>gp', function()
      require('neogit').open { 'push' }
    end, { desc = '[G]it [P]ush' })
    vim.keymap.set('n', '<leader>gl', function()
      require('neogit').open { 'log' }
    end, { desc = '[G]it [L]og' })

    -- Diff view keymaps
    vim.keymap.set('n', '<leader>gh', '<cmd>DiffviewFileHistory<CR>', { desc = '[G]it file [H]istory' })

    -- Git window toggle function
    local function toggle_git_window()
      -- Check if we're currently in a git status buffer
      if vim.bo.filetype == 'NeogitStatus' then
        -- Close the git window
        vim.cmd 'close'
        return
      end

      -- Look for existing git status window
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.api.nvim_buf_get_option(buf, 'filetype') == 'NeogitStatus' then
          -- Focus the existing git window
          vim.api.nvim_set_current_win(win)
          -- Close the git window
          vim.cmd 'close'
          return
        end
      end

      -- No git window found, open neogit
      require('neogit').open()
    end

    vim.keymap.set('n', '<leader>tg', toggle_git_window, { desc = '[T]oggle [G]it window' })

    vim.keymap.set('n', '<leader>td', function()
      -- Toggle diffview
      local diffview = require 'diffview.lib'
      local view = diffview.get_current_view()
      if view then
        vim.cmd 'DiffviewClose'
      else
        vim.cmd 'DiffviewOpen'
      end
    end, { desc = '[T]oggle [D]iff view' })

    -- File-specific diff view
    vim.keymap.set('n', '<leader>gf', function()
      local file = vim.fn.expand '%'
      if file ~= '' then
        vim.cmd('DiffviewOpen -- ' .. file)
      else
        print 'No file to diff'
      end
    end, { desc = '[G]it diff current [F]ile' })
  end,
}
