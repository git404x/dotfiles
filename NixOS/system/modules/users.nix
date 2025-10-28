{ pkgs, userConfig, ... }:

let
  shellName = userConfig.shell;
in
{
  # user
  users.users.${userConfig.username} = {
    isNormalUser = true;
    description = userConfig.name;
    useDefaultShell = true;
    extraGroups = [ "wheel" "networkmanager" "input" "video" "audio" "adbusers" ];
    packages = with pkgs; [
      # hello
    ];
  };

  # shell
  programs.${shellName}.enable = true;
  users.defaultUserShell = pkgs.${shellName};
}
