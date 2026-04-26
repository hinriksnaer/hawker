-- Default theme configuration
-- Sets ayu as fallback colorscheme only when no hawker theme is active.
-- theme.lua (managed by hawker-theme-set) takes priority when present.

local theme_file = vim.fn.stdpath 'config' .. '/lua/plugins/theme.lua'
local has_theme = vim.loop.fs_stat(theme_file) ~= nil

return {
  {
    'Shatur/neovim-ayu',
    priority = 1000,
    config = function()
      require('ayu').setup {
        mirage = true,
      }
      -- Only set ayu if no hawker theme is active
      if not has_theme then
        vim.cmd.colorscheme('ayu')
      end
    end,
  },
}
