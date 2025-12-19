return {
  'folke/snacks.nvim',
  opts = {
    gh = {},
    picker = {
      sources = {
        gh_pr = {
          search = function()
            local ok, login = pcall(vim.fn.system, 'gh api user --jq .login')
            if ok and login and login:match '%S' then
              local user = login:gsub('%s+$', '')
              return 'involves:' .. user .. ' is:open'
            else
              return 'is:open'
            end
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
