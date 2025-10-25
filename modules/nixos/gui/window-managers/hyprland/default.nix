# Hyprland Window Manager Configuration
# Modular structure with separate files for each component

{
  imports = [
    ./options.nix      # Custom NixOS options for Hyprland
    ./config.nix       # Main Hyprland configuration
    ./keybinds.nix     # Keybinding configuration
    ./rules.nix        # Window rules and workspace rules
    ./animations.nix   # Animation settings
    ./appearance.nix   # Visual appearance settings
    ./plugins.nix      # Hyprland plugins
    ./scripts.nix      # Custom scripts and utilities
  ];
}