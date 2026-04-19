-- Default theme configuration
-- This file sets a fallback colorscheme when no hawker-theme is active
-- theme.lua (symlinked by hawker-theme-set) will override this when present

return {
  {
    'Shatur/neovim-ayu',
    priority = 1000,
    config = function()
      require('ayu').setup {
        mirage = true,
      }
      -- Set ayu as default colorscheme
      vim.cmd.colorscheme('ayu')
    end,
  },
}
