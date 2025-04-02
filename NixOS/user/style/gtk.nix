{ config, pkgs, userConfig, ... }:

{

  # GTK 
  gtk = {
    enable = true;

    cursorTheme.package = userConfig.themeConfig.cursorPkg;
    cursorTheme.name = userConfig.themeConfig.cursor;

    theme.package = userConfig.themeConfig.themePkg;
    theme.name = userConfig.themeConfig.theme;

    iconTheme.package = userConfig.themeConfig.iconPkg;
    iconTheme.name = userConfig.themeConfig.icon;

  };

}
