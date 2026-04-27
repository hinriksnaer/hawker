-- Hawker theme: ayu-dark
-- Override background to match VSCode's teabyii.ayu dark (#10141c)
return {
  {
    "Shatur/neovim-ayu",
    priority = 1000,
    lazy = false,
    config = function()
      require("ayu").setup({
        overrides = {
          Normal = { bg = "#10141c" },
          NormalFloat = { bg = "#141821" },
          SignColumn = { bg = "#10141c" },
          FoldColumn = { bg = "#10141c" },
        },
      })
      vim.cmd.colorscheme("ayu-dark")
    end,
  },
}
