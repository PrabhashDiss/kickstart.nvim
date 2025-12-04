return {
  'mfussenegger/nvim-jdtls',
  ft = { 'java' },
  config = function()
    -- Prefer JAVA_HOME if set, otherwise fall back to `java` in PATH
    local java_executable = os.getenv('JAVA_HOME') and (os.getenv('JAVA_HOME') .. '/bin/java') or 'java'

    -- Determine jdtls installation path
    -- Priority: $JDTLS_HOME, custom-ls tree, mason registry, or mason default path
    local jdtls_home_env = os.getenv 'JDTLS_HOME'
    local mason_registry_ok, mason_registry = pcall(require, 'mason-registry')
    local data_std = vim.fn.stdpath('data')
    local sep = package.config:sub(1, 1)
    local custom_ls_path = data_std .. sep .. 'custom-ls' .. sep .. 'packages' .. sep .. 'jdtls'
    local mason_path = data_std .. sep .. 'mason' .. sep .. 'packages' .. sep .. 'jdtls'
    local jdtls_path = nil
    if jdtls_home_env and vim.fn.isdirectory(jdtls_home_env) == 1 then
      jdtls_path = jdtls_home_env
    elseif vim.fn.isdirectory(custom_ls_path) == 1 then
      jdtls_path = custom_ls_path
    elseif mason_registry_ok and mason_registry.has_package and mason_registry.has_package 'jdtls' then
      local pkg = mason_registry.get_package 'jdtls'
      -- Guard against different mason versions where method may not exist
      if pkg and type(pkg.get_install_path) == 'function' then
        jdtls_path = pkg:get_install_path()
      else
        jdtls_path = mason_path
      end
    else
      jdtls_path = mason_path
    end

    local jdtls_ok, jdtls = pcall(require, 'jdtls')
    if not jdtls_ok then
      vim.notify('jdtls: could not load jdtls plugin', vim.log.levels.ERROR)
      return
    end

    -- Determine OS name
    local os_name = (vim.uv or vim.loop).os_uname().sysname

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

    if not (jdtls_path and jdtls_path ~= '') or vim.fn.isdirectory(jdtls_path) ~= 1 then
      local hint = string.format([[
jdtls: couldn't find jdtls installation.
You can install it via Mason (:Mason -> jdtls) or place the unpacked jdtls under:
  %s/custom-ls/packages/jdtls
or set $JDTLS_HOME to the folder containing jdtls's `plugins/` and `config_*` directories.
]], vim.fn.stdpath('data'))
      vim.notify(hint, vim.log.levels.ERROR)
      return
    end

    local jdtls_cmd = {
      -- 💀
      java_executable, -- '/path/to/java11_or_newer/bin/java'
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
      (function()
        local jar = vim.fn.glob(jdtls_path .. '/plugins/org.eclipse.equinox.launcher_*.jar')
        if not jar or jar == '' then
          vim.notify('jdtls: could not find the equinox launcher jar in: ' .. jdtls_path .. '/plugins', vim.log.levels.ERROR)
        end
        return jar
      end)(),
      -- Must point to the                         Change this to
      -- eclipse.jdt.ls installation               the actual version

      -- 💀
      '-configuration',
      jdtls_path .. '/config_' .. (os_name == 'Windows_NT' and 'win' or os_name == 'Linux' and 'linux' or 'mac'),
      -- eclipse.jdt.ls installation            Depending on your system.

      -- 💀
      -- See `data directory configuration` section in the README
      '-data',
      workspace_dir,
    }

    local blink_cmp_ok, blink_cmp = pcall(require, 'blink.cmp')
    local capabilities = (blink_cmp_ok and blink_cmp.get_lsp_capabilities and blink_cmp.get_lsp_capabilities()) or vim.lsp.protocol.make_client_capabilities()

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
    local jdtls_augroup = vim.api.nvim_create_augroup('jdtls-buffer-attach', { clear = true })
    vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
      group = jdtls_augroup,
      pattern = '*.java',
      callback = function(args)
        -- Determine buffer root
        local buf_path = vim.api.nvim_buf_get_name(args.buf)
        local jdtls_setup = require 'jdtls.setup'
        local b_root = jdtls_setup.find_root(root_markers, buf_path)
        if not b_root then
          return
        end

        -- Create a fresh config for this buffer/root so we don't mutate shared state
        local b_project_name = vim.fn.fnamemodify(b_root, ':p:t')
        local sep = package.config:sub(1, 1)
        local b_workspace = vim.fn.stdpath 'data' .. sep .. 'jdtls-workspace' .. sep .. b_project_name
        vim.fn.mkdir(b_workspace, 'p')

        local b_cmd = vim.deepcopy(jdtls_cmd)
        for i = 1, #b_cmd do
          if b_cmd[i] == '-data' and i < #b_cmd then
            b_cmd[i + 1] = b_workspace
            break
          end
        end

        local b_config = {
          cmd = b_cmd,
          root_dir = b_root,
          capabilities = capabilities,
          settings = vim.deepcopy(config.settings),
          init_options = config.init_options,
        }

        jdtls.start_or_attach(b_config)
      end,
    })
  end,
}
