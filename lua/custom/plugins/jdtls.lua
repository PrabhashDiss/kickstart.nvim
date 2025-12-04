return {
  'mfussenegger/nvim-jdtls',
  ft = { 'java' },
  config = function()
    local jdtls_ok, jdtls = pcall(require, 'jdtls')
    if not jdtls_ok then
      vim.notify('jdtls: could not load jdtls plugin', vim.log.levels.ERROR)
      return
    end

    -- Determine OS name
    local os_name = vim.loop.os_uname().sysname

    -- Find project root
    local root_markers = { '.git', 'mvnw', 'gradlew' }
    local root_dir = require('jdtls.setup').find_root(root_markers)
    if not root_dir then
      vim.notify('jdtls: could not determine project root', vim.log.levels.WARN)
      return
    end

    -- Workspace directory per project
    local project_name = vim.fn.fnamemodify(root_dir, ':p:t')
    local workspace_dir = vim.fn.stdpath 'data' .. package.config:sub(1, 1) .. 'jdtls-workspace' .. package.config:sub(1, 1) .. project_name

    local jdtls_cmd = {
      -- 💀
      '/usr/lib/jvm/java-17-openjdk-amd64/bin/java', -- '/path/to/java11_or_newer/bin/java'
      -- depends on if `java` is in your $PATH env variable and if it points to the right version.

      '-Declipse.application=org.eclipse.jdt.ls.core.id1',
      '-Dosgi.bundles.defaultStartLevel=4',
      '-Declipse.product=org.eclipse.jdt.ls.core.product',
      '-Dlog.protocol=true',
      '-Dlog.level=ALL',
      '-Xms1g',
      '--add-modules=ALL-SYSTEM',
      '--add-opens',
      'java.base/java.util=ALL-UNNAMED',
      '--add-opens',
      'java.base/java.lang=ALL-UNNAMED',

      -- '-javaagent',
      -- vim.fn.stdpath 'data'
      --   .. package.config:sub(1, 1)
      --   .. 'custom-ls'
      --   .. package.config:sub(1, 1)
      --   .. 'packages'
      --   .. package.config:sub(1, 1)
      --   .. 'jdtls'
      --   .. package.config:sub(1, 1)
      --   .. 'lombok.jar',

      -- 💀
      '-jar',
      vim.fn.stdpath 'data'
        .. package.config:sub(1, 1)
        .. 'custom-ls'
        .. package.config:sub(1, 1)
        .. 'packages'
        .. package.config:sub(1, 1)
        .. 'jdtls'
        .. package.config:sub(1, 1)
        .. 'plugins'
        .. package.config:sub(1, 1)
        .. 'org.eclipse.equinox.launcher_1.6.500.v20230717-2134.jar',
      -- Must point to the                         Change this to
      -- eclipse.jdt.ls installation               the actual version

      -- 💀
      '-configuration',
      vim.fn.stdpath 'data'
        .. package.config:sub(1, 1)
        .. 'custom-ls'
        .. package.config:sub(1, 1)
        .. 'packages'
        .. package.config:sub(1, 1)
        .. 'jdtls'
        .. package.config:sub(1, 1)
        .. 'config_'
        .. (os_name == 'Windows_NT' and 'win' or os_name == 'Linux' and 'linux' or 'mac'),
      -- eclipse.jdt.ls installation            Depending on your system.

      -- 💀
      -- See `data directory configuration` section in the README
      '-data',
      workspace_dir,
    }

    local capabilities = require('blink.cmp').get_lsp_capabilities()

    -- See `:help vim.lsp.start_client` for an overview of the supported `config` options.
    local config = {
      -- The command that starts the language server
      -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
      cmd = jdtls_cmd,

      -- 💀
      -- One dedicated LSP server & client will be started per unique root_dir
      root_dir = root_dir,

      capabilities = capabilities,

      -- Here you can configure eclipse.jdt.ls specific settings
      -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
      -- for a list of options
      settings = {
        java = {
          -- Add your eclipse.jdt.ls java settings here if needed
          format = {
            enabled = true,
            settings = {
              tabWidth = 4,
              indentWidth = 4,
              -- These are crucial for telling JDTLS how to format
              -- You might also need to specify a profile if using specific Eclipse formatter files
              -- profile = "org.eclipse.jdt.core.prefs", -- Example: Points to default
              --
              -- If you have a specific formatter XML file, you would point to it like this:
              -- profile = "/path/to/your/custom_eclipse_formatter.xml",
              eclipse = {
                clean = 'true',
                format = 'true',
              },
            },
          },
        },
      },

      -- Language server `initializationOptions`
      -- You need to extend the `bundles` with paths to jar files
      -- if you want to use additional eclipse.jdt.ls plugins.
      --
      -- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
      --
      -- If you don't plan on using the debugger or other eclipse.jdt.ls plugins you can remove this
      init_options = {
        bundles = {},
      },
    }

    -- This starts a new client & server,
    -- or attaches to an existing client & server depending on the `root_dir`.
    jdtls.start_or_attach(config)

    -- Ensure any Java buffer opened later (e.g. via go-to-definition) will also attach
    vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
      pattern = '*.java',
      callback = function(args)
        -- Determine buffer root
        local buf_path = vim.api.nvim_buf_get_name(args.buf)
        local jdtls_setup = require 'jdtls.setup'
        local b_root = jdtls_setup.find_root(root_markers, buf_path) or root_dir
        if not b_root then
          return
        end
        -- Update `config.root_dir` and workspace when buffer root differs
        if b_root ~= config.root_dir then
          config.root_dir = b_root
          local b_project_name = vim.fn.fnamemodify(b_root, ':t')
          local sep = package.config:sub(1, 1)
          local b_workspace = vim.fn.stdpath 'data' .. sep .. 'jdtls-workspace' .. sep .. b_project_name
          vim.fn.mkdir(b_workspace, 'p')
          config.cmd = vim.deepcopy(jdtls_cmd) -- preserve original cmd template
          -- Locate the `-data` arg and replace its value with the new workspace path
          for i = 1, #config.cmd do
            if config.cmd[i] == '-data' and i < #config.cmd then
              config.cmd[i + 1] = b_workspace
              break
            end
          end
        end
        jdtls.start_or_attach(config)
      end,
    })
  end,
}
