{ pkgs, username, ... }:

{
  # user
  users.users.${username} = {
    isNormalUser = true;
    description = "";
    useDefaultShell = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "input"
      "video"
      "audio"
      "adbusers"
    ];
    packages = with pkgs; [ ];
  };

  # shell
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;
}
