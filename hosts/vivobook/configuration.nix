{
  dotfiles,
  ...
}:

{

  imports = [
    "${dotfiles}/modules/nixos/hardware/amdgpu.nix"
    "${dotfiles}/modules/nixos/hardware/zen1.nix"
    "${dotfiles}/modules/nixos/core"
    "${dotfiles}/modules/nixos/gui"
    "${dotfiles}/modules/nixos/extra"
  ];

}
