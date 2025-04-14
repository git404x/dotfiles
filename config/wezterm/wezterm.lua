-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- config
config.font = wezterm.font("JetBrainsMono NF")
config.font_size = 10

config.enable_tab_bar = false
config.window_decorations = "NONE"
config.window_background_opacity = 0.95
config.macos_window_background_blur = 10

-- colorscheme function
local function scheme_for_appearance(appearance)
  if appearance:find("Dark") then
    return "Catppuccin Mocha"
  else
    return "Catppuccin Latte"
  end
end

-- Set the color scheme based on current appearance
config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())

-- Return the configuration to wezterm
return config
