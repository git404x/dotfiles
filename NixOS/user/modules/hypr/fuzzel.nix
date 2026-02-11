{ pkgs, ... }:

{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        # behaviour
        terminal = "${pkgs.foot}/bin/foot -e";
        icons-enabled = "yes";
        fields = "filename,name,generic";
        password-character = "*";
        match-mode = "fzf";
        sort-result = "yes";
        match-counter = "yes";
        show-actions = "no";

        # interface
        prompt = ">>";
        placeholder = "search";
        dpi-aware = "auto";
        use-bold = "yes";
        hide-before-typing = "no";

        # layout
        anchor = "center";
        x-margin = 10;
        y-margin = 10;
        lines = 10;
        width = 34;
        tabs = 8;
        "horizontal-pad" = 30;
        "vertical-pad" = 20;
        "inner-pad" = 10;

        # window
        layer = "overlay";
        "keyboard-focus" = "exclusive";
        "exit-on-keyboard-focus-loss" = "yes";
        "enable-mouse" = "yes";
      };

      dmenu = {
        mode = "text";
        "exit-immediately-if-empty" = "no";
      };

      border = {
        width = 2;
        radius = 10;
      };
    };
  };
}
