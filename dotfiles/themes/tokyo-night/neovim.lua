-- Hawker theme: tokyo-night
return {
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      colorscheme = "tokyonight-night",
    },
    config = function()
      vim.cmd.colorscheme("tokyonight-night")
    end,
  },
}
