return {
  -- {
  --   "bluz71/vim-nightfly-guicolors",
  --   priority = 1000, -- make sure to load this before all the other start plugins
  --   config = function()
  --     -- load the colorscheme here
  --     vim.cmd([[colorscheme nightfly]])
  --   end,
  -- },
  {
    "folke/tokyonight.nvim",
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      local bg = "#011628"
      local bg_dark = "#011423"
      local bg_highlight = "#143652"
      local bg_search = "#0A64AC"
      local bg_visual = "#275378"
      local fg = "#CBE0F0"
      local fg_dark = "#B4D0E9"
      local fg_gutter = "#627E97"
      local border = "#547998"

      -- only enable transparency in nvim when using iTerm2
      -- NB: also need to enable it in iTerm2, including the "keep background colors opaque" setting
      local transbool = nil
      local styles = nil
      local trans = nixCats.extra("isItermTrans")
      if vim.env.ITERM_SESSION_ID ~= nil and trans then
        transbool = true
        styles = { sidebars = "transparent", floats = "transparent" } -- "dark", "transparent" or "normal"
      else
        transbool = false
        styles = { sidebars = "dark", floats = "dark" }
      end

      require("tokyonight").setup({
        style = "night",
        transparent = transbool, -- Disable the background
        -- Background styles. Can be "dark", "transparent" or "normal"
        styles = styles,
        on_colors = function(colors)
          colors.bg = bg
          colors.bg_dark = bg_dark
          colors.bg_float = bg_dark
          colors.bg_highlight = bg_highlight
          colors.bg_popup = bg_dark
          colors.bg_search = bg_search
          colors.bg_sidebar = bg_dark
          colors.bg_statusline = colors.none
          colors.bg_visual = bg_visual
          colors.border = border
          colors.fg = fg
          colors.fg_dark = fg_dark
          colors.fg_float = fg
          colors.fg_gutter = fg_gutter
          colors.fg_sidebar = fg_dark
        end,
        on_highlights = function(highlights, colors)
          if vim.env.ITERM_SESSION_ID ~= nil then
            -- TabLineFill is currently set to black
            highlights.TabLineFill = {
              bg = colors.none,
            }
            highlights.Normal = {
              bg = colors.none,
            }
            highlights.NormalNC = {
              bg = colors.none,
            }
            highlights.NormalFloat = {
              bg = colors.none,
            }
            highlights.NormalSB = {
              bg = colors.none,
            }
            highlights.MsgArea = {
              bg = colors.none,
            }
          end
        end,
      })
      -- load the colorscheme here
      vim.cmd("colorscheme tokyonight")
    end,
  },
}
