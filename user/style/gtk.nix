{ config, pkgs, userConfig, ... }:

let

  pkg-kora-icons = import ./kora-icons.nix { inherit pkgs; };

in

{

  # GTK 
  gtk = {
    enable = true;

    cursorTheme.package = userConfig.themeConfig.cursorPkg;
    cursorTheme.name = userConfig.themeConfig.cursor;

    theme.package = userConfig.themeConfig.themePkg;
    theme.name = userConfig.themeConfig.theme;

    iconTheme.package = pkg-kora-icons;
    iconTheme.name = "kora";
    # Kora has kora , kora-light , kora-light-panel , kora-pgrey variants

  };

}
