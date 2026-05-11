{
  inputs,
  pkgs,
  userConfig,
  ...
}:
let
  game-sh = builtins.readFile ./../../../scripts/game.sh;
  gamerun = pkgs.writeShellScriptBin "gamerun" game-sh;
in
{
  imports = [
    inputs.nix-craft.nixosModules.client
    inputs.nix-craft.nixosModules.server
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
        start = "${gamerun}/bin/gamerun power max";
        end = "${gamerun}/bin/gamerun power default";
      };
    };
  };

  users.users.${userConfig.username}.extraGroups = [ "gamemode" ];
  security.wrappers.ryzenadj = {
    source = "${pkgs.ryzenadj}/bin/ryzenadj";
    owner = "root";
    group = "root";
    setuid = true;
  };

  environment.systemPackages = with pkgs; [
    mangohud
    goldberg-emu
    gamerun
    ppsspp

    (retroarch.withCores (
      cores: with cores; [
        mgba
        ppsspp
      ]
    ))

  ];
}
