return {
  'folke/snacks.nvim',
  opts = {
    gh = {},
    picker = {
      sources = {
        gh_pr = {
            search = function()
              local login = vim.fn.system('gh api user --jq .login')
              if vim.v.shell_error ~= 0 then
                return 'is:open'
              end
              login = (login or ''):gsub('%s+$', '')
              if login == '' then
                return 'is:open'
              end
              return 'involves:' .. login .. ' is:open'
            end,
        },
      },
    },
  },
  keys = {
    {
      '<leader>gp',
      function()
        require('snacks').picker.gh_pr()
      end,
      desc = '[G]itHub [P]ull Requests',
    },
  },
  config = function(_, opts)
    require('snacks').setup(opts)
  end,
}
