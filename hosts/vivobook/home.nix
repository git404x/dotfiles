{
  dotfiles,
  username,
  ...
}:

{

  imports = [
    "${dotfiles}/modules/home/core"
    "${dotfiles}/modules/home/gui"
    "${dotfiles}/modules/home/extra"
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  programs.vcam = {
    enable = true;
    device = "/dev/video10";
    startSource = "black";
  };

}
