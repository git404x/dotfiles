{ config, pkgs, ... }:

let

  pkg-kora-icons = import ./kora-icons.nix { inherit pkgs; };

in

{

  # GTK 
  gtk = {
    enable = true;

    cursorTheme.package = pkgs.bibata-cursors;
    cursorTheme.name = "Bibata-Modern-Ice";

    theme.package = pkgs.whitesur-gtk-theme;
    theme.name = "WhiteSur-Dark";

    iconTheme.package = pkg-kora-icons;
    iconTheme.name = "kora";
    # Kora has kora , kora-light , kora-light-panel , kora-pgrey variants

  };

}
