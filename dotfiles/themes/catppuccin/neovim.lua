-- Hawker theme: catppuccin
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    opts = {
      colorscheme = "catppuccin",
    },
    config = function()
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
