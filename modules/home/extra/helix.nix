{ pkgs, ... }:

{
  programs.helix = {
    enable = true;
    defaultEditor = false;

    settings = {
      editor = {
        line-number = "relative";
        cursorline = true;
        color-modes = true;
        bufferline = "multiple";

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };

        indent-guides = {
          render = true;
          character = "│";
        };
      };

      keys.normal = {
        space.x = ":buffer-close"; # quick close buffer
        esc = [
          "collapse_selection"
          "keep_primary_selection"
        ];
      };
    };
  };
}
