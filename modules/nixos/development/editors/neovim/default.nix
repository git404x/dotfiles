# Neovim Editor Configuration
# Modular structure with separate plugin configurations

{
  imports = [
    ./options.nix     # Custom NixOS options for Neovim
    ./plugins         # Plugin configurations directory
    ./keybinds.nix    # Keybinding configuration
    ./lsp.nix         # Language Server Protocol setup
    ./appearance.nix  # UI and theming configuration
    ./autocmds.nix    # Auto commands and events
  ];
}