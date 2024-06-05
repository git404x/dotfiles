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

    theme.package = pkgs.adw-gtk3;
    theme.name = "adw-gtk3";

    iconTheme.package = pkg-kora-icons;
    iconTheme.name = "kora";
    # Kora has kora , kora-light , kora-light-panel , kora-pgrey variants

  };

}
