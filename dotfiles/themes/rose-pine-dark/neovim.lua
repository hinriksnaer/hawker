-- Hawker theme: rose-pine-dark
return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
    lazy = false,
    opts = {
      colorscheme = "rose-pine",
    },
    config = function()
      vim.cmd.colorscheme("rose-pine")
    end,
  },
}
