-- Hawker theme: ayu-dark
return {
  {
    "Shatur/neovim-ayu",
    priority = 1000,
    lazy = false,
    opts = {
      colorscheme = "ayu-dark",
    },
    config = function()
      vim.cmd.colorscheme("ayu-dark")
    end,
  },
}
