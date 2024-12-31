local java_cmds = vim.api.nvim_create_augroup('java_cmds', { clear = true })

local get_platform = function()
  if vim.fn.has 'mac' then
    return 'mac_arm'
  elseif vim.fn.has 'win32' then
    return 'win'
  else
    return 'linux'
  end
end

return {
  {
    'mfussenegger/nvim-jdtls',
    opts = {
      root_markers = { '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle' },
    },
    config = function(_, opts)
      local resolve_opts = function()
        local root_dir = require('jdtls.setup').find_root(opts.root_markers)
        local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
        local workspace_dir = vim.fn.stdpath 'cache' .. '/jdtls/workspace-root/' .. project_name
        if vim.loop.fs_stat(workspace_dir) == nil then
          os.execute('mkdir ' .. workspace_dir)
        end
        local install_path = require('mason-registry').get_package('jdtls'):get_install_path()
        local platform = get_platform()

        return {
          cmd = {
            'java',
            '-Declipse.application=org.eclipse.jdt.ls.core.id1',
            '-Dosgi.bundles.defaultStartLevel=4',
            '-Declipse.product=org.eclipse.jdt.ls.core.product',
            '-Dlog.protocol=true',
            '-Dlog.level=ALL',
            '-javaagent:' .. install_path .. '/lombok.jar',
            '-Xmx1g',
            '--add-modules=ALL-SYSTEM',
            '--add-opens',
            'java.base/java.util=ALL-UNNAMED',
            '--add-opens',
            'java.base/java.lang=ALL-UNNAMED',
            '-jar',
            vim.fn.glob(install_path .. '/plugins/org.eclipse.equinox.launcher_*.jar'),
            '-configuration',
            install_path .. '/config_' .. platform,
            '-data',
            workspace_dir,
          },
          root_dir = root_dir,
        }
      end
      local jdtls_setup = function(event)
        local start_opts = resolve_opts()
        require('jdtls').start_or_attach(start_opts)
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end
        map('<leader>cv', function()
          vim.cmd 'normal! \28\14'
          require('jdtls').extract_variable_all { visual = true, name = vim.fn.input 'Name > ' }
        end, 'Extract [V]ariable', { 'v' })
        map('<leader>cm', function()
          vim.cmd 'normal! \28\14'
          require('jdtls').extract_method { visual = true, name = vim.fn.input 'Name > ' }
        end, 'Extract [M]ethod', { 'v' })
        map('<leader>cc', function()
          vim.cmd 'normal! \28\14'
          require('jdtls').extract_constant { visual = true, name = vim.fn.input 'Name > ' }
        end, 'Extract [C]onstant', { 'v' })
        map('<leader>ci', function()
          require('jdtls').organize_imports()
        end, 'Organize [I]mports')
      end
      vim.api.nvim_create_autocmd('Filetype', {
        group = java_cmds,
        pattern = 'java',
        desc = 'Setup jdtls',
        callback = jdtls_setup,
      })
    end,
  },
}
