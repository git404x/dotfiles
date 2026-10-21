{
  dotfiles,
  ...
}:

{

  imports = [
    "${dotfiles}/modules/nixos/hardware/amdgpu.nix"
    "${dotfiles}/modules/nixos/hardware/vcam.nix"
    "${dotfiles}/modules/nixos/core"
    "${dotfiles}/modules/nixos/gui"
    "${dotfiles}/modules/nixos/extra"
  ];

  hardware.vcam = {
    enable = true;
    videoNr = 10;
    label = "HD WebCam";
  };
}
