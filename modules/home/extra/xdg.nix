{ ... }:

{
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "org.qutebrowser.qutebrowser.desktop" ];
      "x-scheme-handler/http" = [ "org.qutebrowser.qutebrowser.desktop" ];
      "x-scheme-handler/https" = [ "org.qutebrowser.qutebrowser.desktop" ];
      "x-scheme-handler/about" = [ "org.qutebrowser.qutebrowser.desktop" ];
      "x-scheme-handler/unknown" = [ "org.qutebrowser.qutebrowser.desktop" ];

      "image/jpeg" = [
        "imv.desktop"
        "org.gnome.Loupe.desktop"
      ];
      "image/png" = [
        "imv.desktop"
        "org.gnome.Loupe.desktop"
      ];
      "image/webp" = [
        "imv.desktop"
        "org.gnome.Loupe.desktop"
      ];
      "image/gif" = [
        "imv.desktop"
        "org.gnome.Loupe.desktop"
      ];
      "image/svg+xml" = [
        "imv.desktop"
        "org.gnome.Loupe.desktop"
      ];

      "application/pdf" = [
        "org.pwmt.zathura.desktop"
        "stirling-pdf-desktop.desktop"
      ];
    };
  };
}
