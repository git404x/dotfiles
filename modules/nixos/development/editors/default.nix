# Editors Module
# Imports all editor configurations

{
  imports = [
    # Text Editors
    ./neovim      # Modern Vim-based editor
    ./emacs       # Emacs with Evil mode
    ./nano        # Simple terminal editor
    ./micro       # Modern terminal editor
    
    # IDEs and Specialized Editors
    ./vscode      # Visual Studio Code
    ./zed         # Modern editor
  ];
}