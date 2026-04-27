-- Hawker theme: ayu-dark
-- Patch colors.bg to match VSCode's teabyii.ayu editor background (#10141c).
-- The plugin hardcodes #0B0E14 in colors.generate(), so we intercept it
-- and override bg after generation — all highlight groups then use our value.
return {
  {
    "Shatur/neovim-ayu",
    priority = 1000,
    lazy = false,
    config = function()
      local colors = require("ayu.colors")
      local original_generate = colors.generate
      colors.generate = function(mirage)
        original_generate(mirage)
        if not mirage and vim.o.background == "dark" then
          colors.bg = "#10141c"
          colors.line = "#161a24"
          colors.panel_bg = "#141821"
          colors.panel_shadow = "#0d1017"
        end
      end

      require("ayu").setup({})
      vim.cmd.colorscheme("ayu-dark")
    end,
  },
}
