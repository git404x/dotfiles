{
  dotfiles,
  ...
}:

{

  imports = [
    "${dotfiles}/modules/nixos/hardware/amdgpu.nix"
    "${dotfiles}/pkgs/vcam/module.nix"
    "${dotfiles}/modules/nixos/core"
    "${dotfiles}/modules/nixos/gui"
    "${dotfiles}/modules/nixos/extra"
  ];

  services.vcam.enable = true;

}
