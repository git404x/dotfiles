{ config, lib, pkgs, inputs, systemConfig, ... }:

let
  system = systemConfig.system;
in
{
  environment.systemPackages = [
    inputs.zen-browser.packages."${system}".default
  ];

}
