{ pkgs, userConfig, ... }:

{
  
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${userConfig.username} = {
    isNormalUser = true;
    description = userConfig.name;
    useDefaultShell = true;
    extraGroups = [ "wheel" "networkmanager" "input"  "video" "audio" "adbusers" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tdesktop
      ani-cli
    ];
  };

  # zsh
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  # Change runtime directory size
  services.logind.extraConfig = "RuntimeDirectorySize=8G";

  # user pkgs
  programs = {
    adb.enable = true;
  };
}
