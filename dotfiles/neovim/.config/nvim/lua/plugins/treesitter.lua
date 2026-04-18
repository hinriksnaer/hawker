-- lua/plugins/treesitter.lua
return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    version = false,
    lazy = false,
    build = function()
      local TS = require('nvim-treesitter')
      if not TS.get_installed then
        vim.notify('Please restart Neovim and run :TSUpdate', vim.log.levels.ERROR)
        return
      end
      TS.update(nil, { summary = true })
    end,
    cmd = { 'TSUpdate', 'TSInstall', 'TSLog', 'TSUninstall' },
    dependencies = {
      { 'folke/which-key.nvim' },
    },
    opts = {
      ensure_installed = {
        'bash',
        'c',
        'cpp',
        'css',
        'html',
        'javascript',
        'json',
        'lua',
        'nix',
        'luadoc',
        'markdown',
        'markdown_inline',
        'python',
        'regex',
        'typescript',
        'vim',
        'vimdoc',
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts)
      local TS = require('nvim-treesitter')

      -- Sanity check
      if not TS.get_installed then
        vim.notify('Please update nvim-treesitter via :Lazy', vim.log.levels.ERROR)
        return
      end

      -- Setup treesitter
      TS.setup(opts)

      -- Install missing parsers
      local installed = TS.get_installed()
      local to_install = vim.tbl_filter(function(lang)
        return not vim.tbl_contains(installed, lang)
      end, opts.ensure_installed or {})

      if #to_install > 0 then
        TS.install(to_install, { summary = true })
      end

      -- Enable features per filetype
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter_setup', { clear = true }),
        callback = function(ev)
          local ft = ev.match
          local lang = vim.treesitter.language.get_lang(ft)

          -- Enable highlighting
          if opts.highlight and opts.highlight.enable then
            pcall(vim.treesitter.start, ev.buf)
          end

          -- Enable indentation
          if opts.indent and opts.indent.enable then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
}
