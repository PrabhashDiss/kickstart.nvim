return {
  'mfussenegger/nvim-jdtls',
  ft = { 'java' },
  dependencies = {
    'mfussenegger/nvim-dap',
  },
  config = function()
    local cached_product_variant = os.getenv 'P8_PRODUCT_VARIATION'
    local cached_solution_variant = os.getenv 'P8_SOLUTION_VARIATION'

    local function prompt_and_start()
      local function start_jdtls_with_variants(product_variant, solution_variant)
        cached_product_variant = product_variant
        cached_solution_variant = solution_variant
        require('custom.plugins.jdtls').setup_jdtls(product_variant, solution_variant)
      end
      
      if cached_product_variant and cached_solution_variant then
        start_jdtls_with_variants(cached_product_variant, cached_solution_variant)
        return
      end

      vim.ui.input({ prompt = 'P8 Product Variant: ' }, function(product_input)
        if product_input == nil then
          return -- User cancelled
        end
        local product = product_input ~= '' and product_input or nil

        vim.ui.input({ prompt = 'P8 Solution Variant: ' }, function(solution_input)
          if solution_input == nil then
            return -- User cancelled
          end
          local solution = solution_input ~= '' and solution_input or nil

          start_jdtls_with_variants(product, solution)
        end)
      end)
    end

    local M = {}
    M.setup_jdtls = function(product_variant, solution_variant)
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

    -- Create codelens autocmd to refresh codelens on save
    local codelens_augroup = vim.api.nvim_create_augroup('jdtls-codelens-refresh', { clear = true })
    vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
      group = codelens_augroup,
      pattern = { '*.java' },
      callback = function()
        local _, _ = pcall(vim.lsp.codelens.refresh)
      end,
    })

    local function on_attach(client, bufnr)
      local test_config_overrides = {
        vmArgs = table.concat({
          '-Dlog4j.configurationFile=log4j2-ci-test.properties',
          '-Dp8.product.variant=' .. product_variant,
          '-Dp8.solution.variant=' .. solution_variant,
          '-Dstyle.color=always',
          '-DtrimStackTrace=false',
          '-DfailIfNoTests=false',
          '-Dcheckstyle.skip=true',
          '-Dspotbugs.skip=true',
        }, ' '),
        env = {
          P8_DISABLE_EVENT_PUB = 'true',
        },
      }

      vim.keymap.set('n', '<Leader>jt', function()
        require('jdtls').test_nearest_method { config_overrides = test_config_overrides }
      end, { buffer = bufnr, desc = '[J]DTLS [t]est Nearest Method' })

      vim.keymap.set('n', '<Leader>jT', function()
        require('jdtls').test_class { config_overrides = test_config_overrides }
      end, { buffer = bufnr, desc = '[J]DTLS [T]est Class' })

      vim.lsp.codelens.refresh()
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

    if not jdtls_path or jdtls_path == '' or vim.fn.isdirectory(jdtls_path) ~= 1 then
      local hint = string.format([[
jdtls: couldn't find jdtls installation.
You can install it via Mason (:Mason -> jdtls) or place the unpacked jdtls under:
  %s/custom-ls/packages/jdtls
or set $JDTLS_HOME to the folder containing jdtls's `plugins/` and `config_*` directories.
]], vim.fn.stdpath('data'))
      vim.notify(hint, vim.log.levels.ERROR)
      return
    end

    local lombok_jar = jdtls_path .. '/lombok.jar'

    local launcher_jar = vim.fn.glob(jdtls_path .. '/plugins/org.eclipse.equinox.launcher_*.jar')
    if not launcher_jar or launcher_jar == '' or vim.fn.filereadable(launcher_jar) == 0 then
      vim.notify(
        'jdtls: could not find the equinox launcher jar in: ' .. jdtls_path .. '/plugins',
        vim.log.levels.ERROR
      )
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

      '-Dp8.product.variant=' .. product_variant,
      '-Dp8.solution.variant=' .. solution_variant,
      '-Dstyle.color=always',
      '-DtrimStackTrace=false',
      '-Dmaven.compiler.useIncrementalCompilation=true',

      '-javaagent:'
      .. lombok_jar,

      -- 💀
      '-jar',
      launcher_jar,
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

    local capabilities = {
      workspace = {
        configuration = true,
      },
      textDocument = {
        completion = {
          snippetSupport = false,
        },
      },
    }

    local cmp_nvim_lsp_ok, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
    if cmp_nvim_lsp_ok and type(cmp_nvim_lsp.default_capabilities) == 'function' then
      capabilities = vim.tbl_deep_extend('force', capabilities, cmp_nvim_lsp.default_capabilities())
    end

    local blink_cmp_ok, blink_cmp = pcall(require, 'blink.cmp')
    if blink_cmp_ok and type(blink_cmp.get_lsp_capabilities) == 'function' then
      capabilities = vim.tbl_deep_extend('force', capabilities, blink_cmp.get_lsp_capabilities())
    end

    local custom_packages_path = data_std .. sep .. 'custom-ls' .. sep .. 'packages' .. sep
    local mason_packages_path = data_std .. sep .. 'mason' .. sep .. 'packages' .. sep

    local java_debug_path = custom_packages_path .. 'java-debug-adapter/extension/server'
    if vim.fn.isdirectory(java_debug_path) ~= 1 then
      java_debug_path = mason_packages_path .. 'java-debug-adapter/extension/server'
    end

    local java_test_path = custom_packages_path .. 'java-test/extension/server'
    if vim.fn.isdirectory(java_test_path) ~= 1 then
      java_test_path = mason_packages_path .. 'java-test/extension/server'
    end

    local bundles = {}

    -- debug jars
    local debug_jars = vim.split(vim.fn.glob(java_debug_path .. '/com.microsoft.java.debug.plugin-*.jar', 1), '\n')
    for _, jar in ipairs(debug_jars) do
      if jar ~= '' and vim.fn.filereadable(jar) == 1 then
        table.insert(bundles, jar)
      end
    end

    -- test jars
    local test_jars = vim.split(vim.fn.glob(java_test_path .. '/*.jar', 1), '\n')
    local excluded = { 'com.microsoft.java.test.runner-jar-with-dependencies.jar', 'jacocoagent.jar' }
    for _, test_jar in ipairs(test_jars) do
      if test_jar ~= '' and vim.fn.filereadable(test_jar) == 1 then
        local fname = vim.fn.fnamemodify(test_jar, ':t')
        if not vim.tbl_contains(excluded, fname) then
          table.insert(bundles, test_jar)
        end
      end
    end

    -- See `:help vim.lsp.start_client` for an overview of the supported `config` options.
    local config = {
      -- The command that starts the language server
      -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
      cmd = jdtls_cmd,

      -- 💀
      -- One dedicated LSP server & client will be started per unique root_dir
      root_dir = root_dir,

      capabilities = capabilities,

      on_attach = on_attach,

      -- Here you can configure eclipse.jdt.ls specific settings
      -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
      -- for a list of options
      settings = {
        java = {
          -- Add your eclipse.jdt.ls java settings here if needed
          eclipse = {
            downloadSources = true,
          },
          configuration = {
            updateBuildConfiguration = 'automatic',
            runtimes = {},
          },
          maven = {
            downloadSources = true,
            updateSnapshots = true,
          },
          compile = {
            nullAnalysis = {
              mode = 'automatic',
            },
          },
          import = {
            maven = {
              enabled = true,
            },
            gradle = {
              enabled = false,
            },
          },
          autobuild = {
            enabled = true,
          },
          implementationsCodeLens = {
            enabled = true,
          },
          referencesCodeLens = {
            enabled = true,
          },
          inlayHints = {
            enabled = true,
          },
          references = {
            includeDecompiledSources = true,
          },
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
          signatureHelp = { enabled = true },
          contentProvider = { preferred = 'fernflower' },
          sources = {
            organizeImports = {
              starThreshold = 9999,
              staticStarThreshold = 9999,
            },
          },
          codeGeneration = {
            toString = {
              template = '${object.className}{${member.name()}=${member.value}, ${otherMembers}}',
            },
            hashCodeEquals = {
              useJava7Objects = true,
            },
            useBlocks = true,
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
        bundles = bundles,
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
          on_attach = on_attach,
          settings = vim.deepcopy(config.settings),
          init_options = config.init_options,
        }

        jdtls.start_or_attach(b_config)
      end,
    })
    end

    package.loaded['custom.plugins.jdtls'] = M

    prompt_and_start()
  end,
}
