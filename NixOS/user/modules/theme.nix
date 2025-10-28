{ pkgs, ... }:

{
  # GTK
  gtk = {
    enable = true;
    colorScheme = "dark";
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      size = 24;
      package = pkgs.bibata-cursors;

    };
  };

  # QT
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
    style.name = "adwaita-dark";
    style.package = pkgs.adwaita-qt;
  };

  home.packages = with pkgs; [
    libadwaita
    adw-gtk3
    adwaita-qt
    gnome-themes-extra
    adwaita-icon-theme
  ];

  home.sessionVariables = {
    GTK_THEME = "adw-gtk3-dark";
    ICON_THEME = "Papirus";
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
    QT_QPA_PLATFORMTHEME= "gtk3";
    QT_STYLE_OVERRIDE= "adwaita-dark";
  };
}
