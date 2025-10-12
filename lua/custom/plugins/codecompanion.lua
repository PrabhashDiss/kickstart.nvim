return {
  'olimorris/codecompanion.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  opts = {
    log_level = 'DEBUG', -- or "TRACE"
    prompt_library = {
      git_commit = require 'custom.plugins.codecompanion.prompts.git_commit',
    },
  },
}
