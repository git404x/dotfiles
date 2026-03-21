{ inputs, pkgs, lib, config, userConfig, ... }:
let
  gamerun-script = builtins.readFile ./../../../scripts/game.sh;
  gamerun      = pkgs.writeShellScriptBin "gamerun" gamerun-script;
in
{
  imports = [
    inputs.nix-craft.nixosModules.client
    inputs.nix-craft.nixosModules.server
  ];

  # prevent unstable sleep states
  boot.kernelParams = [
    "amdgpu.noretry=0"
  ];

  services.nix-craft-server = {
    enable = true;
    serverName = "shin-sekai";
    ramAlloc = "2G";
    loader = "fabric";
    mcVersion = "1_21_11";
    enableTailscale = true;
    openFirewall = false;

    mods = [
      {
        name = "fabric-api";
        url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/DdVHbeR1/fabric-api-0.141.1%2B1.21.11.jar";
        sha256 = "sha256-ald/g72LM8lAQSfRZTGsycQZX0feA5WVfJ1M0J17mMY=";
      }
      {
        name = "lithium";
        url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/gl30uZvp/lithium-fabric-0.21.2%2Bmc1.21.11.jar";
        sha256 = "sha256-MQZjnHPuI/RL++Xl56gVTf460P1ISR5KhXZ1mO17Bzk=";
      }
      {
        name = "easyauth";
        url = "https://cdn.modrinth.com/data/aZj58GfX/versions/LPQE6Dfu/easyauth-mc1.21.11-3.4.1.jar";
        sha256 = "sha256-oBKhyVAii4rdfE20w+EhrZddVn68rM/buycc1oHgSZQ=";
      }
    ];
  };

  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  programs.gamemode = {
    enable = true;
    enableRenice = true;
    settings = {
      general = {
        softrealtime = "off";
        renice = 0;
        desiredgov = "default";
      };
      custom = {
        start = "/run/wrappers/bin/sudo ${pkgs.ryzenadj}/bin/ryzenadj --stapm-limit=15000 --fast-limit=18000 --slow-limit=15000 --tctl-temp=80";
        end = "/run/wrappers/bin/sudo ${pkgs.ryzenadj}/bin/ryzenadj --stapm-limit=15000 --fast-limit=25000 --slow-limit=15000 --tctl-temp=95";
      };
    };
  };

  users.users.${userConfig.username}.extraGroups = [ "gamemode" ];
  security.sudo.extraRules = [
  {
    users = [ "${userConfig.username}" ];
    commands = [
    { command = "${pkgs.ryzenadj}/bin/ryzenadj"; options = [ "NOPASSWD" ]; }
    ];
  }
  ];

  environment.systemPackages = with pkgs; [
    ryzenadj
    mangohud
    goldberg-emu
    gamerun
  ];
}
