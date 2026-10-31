{ dotfiles, ... }:
{
  imports = [
    "${dotfiles}/pkgs/vcam/module.nix"
  ];

  services.vcam = {
    enable = true;
    blacklistOnBoot = true;
    deviceNr = 10;
    webcamLabel = "HD WebCam";
    micName = "Virtual_Microphone";
    defaultFeed = "privacy";
  };
}
