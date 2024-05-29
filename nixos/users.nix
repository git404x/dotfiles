{ pkgs, ... }:

{
  
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.itz_levi_404 = {
    isNormalUser = true;
    description = "Levi";
    extraGroups = [ "wheel" "networkmanager" "input"  "video" "audio" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      firefox
      tree
      tdesktop
      git
      gh
    ];
  };

  # Change runtime directory size
  services.logind.extraConfig = "RuntimeDirectorySize=8G";
}
