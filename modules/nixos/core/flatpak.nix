{ ... }:

{
  services.flatpak = {
    enable = true;
    update.onActivation = false;
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };

    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];

    packages = [
      "com.github.tchx84.Flatseal"
      "io.github.flattool.Warehouse"
      {
        appId = "org.freedownloadmanager.Manager";
        origin = "flathub";
      }
    ];
  };
}
