local M = {}

function M.live_grep(opts)
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local make_entry = require 'telescope.make_entry'
  local conf = require('telescope.config').values
  local sorters = require 'telescope.sorters'

  opts = opts or {}
  opts.cwd = opts.cwd or vim.fn.getcwd()

  local finder = finders.new_async_job {
    command_generator = function(prompt)
      if not prompt or prompt == '' then
        return nil
      end

      local pieces = {}
      for _, p in ipairs(vim.split(prompt, '  ', { plain = true })) do
        table.insert(pieces, vim.trim(p))
      end
      local args = { 'rg' }

      -- Pattern
      if pieces[1] and pieces[1] ~= '' then
        table.insert(args, '-e')
        table.insert(args, pieces[1])
      end

      -- File globs
      if pieces[2] and pieces[2] ~= '' then
        for _, g in ipairs(vim.split(pieces[2], ',')) do
          g = vim.trim(g)
          if g ~= '' then
            table.insert(args, '-g')
            table.insert(args, g)
          end
        end
      end

      -- Folder patterns
      if pieces[3] and pieces[3] ~= '' then
        for _, folder in ipairs(vim.split(pieces[3], ',')) do
          folder = vim.trim(folder)
          if folder ~= '' then
            -- Support flexible path matching
            if folder:match '%*' then
              -- Already has wildcards
              table.insert(args, '-g')
              table.insert(args, folder)
            else
              -- No wildcards
              folder = folder:gsub('/$', '')
              table.insert(args, '-g')
              table.insert(args, '**/' .. folder .. '/**')
            end
          end
        end
      end

      local base = { '--color=never', '--no-heading', '--with-filename', '--line-number', '--column', '--smart-case' }
      return vim.tbl_flatten { args, base }
    end,
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,
  }

  pickers
    .new(opts, {
      debounce = 100,
      prompt_title = 'Live Grep',
      finder = finder,
      previewer = conf.grep_previewer(opts),
      sorter = sorters.empty(),
    })
    :find()
end

function M.pick_folder_and_live_grep(opts)
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local sorters = require 'telescope.sorters'
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'
  local themes = require 'telescope.themes'

  opts = opts or {}
  local cwd = opts.cwd or vim.fn.getcwd()

  local cmd
  if vim.fn.executable 'fd' == 1 then
    cmd = { 'fd', '-t', 'd', '--hidden', '--follow', '--exclude', '.git' }
  else
    cmd = { 'find', '.', '-type', 'd', '-not', '-path', '*/.git/*' }
  end

  local finder = finders.new_oneshot_job(cmd, { cwd = cwd })

  pickers
    .new(themes.get_dropdown { prompt_title = 'Select Folder', cwd = cwd }, {
      finder = finder,
      sorter = sorters.get_fuzzy_file(),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if not selection then
            return
          end
          local folder = selection.value or selection[1]
          -- Make absolute
          folder = vim.fn.fnamemodify(folder, ':p')
          M.live_grep { cwd = folder }
        end)
        return true
      end,
    })
    :find()
end

return M
