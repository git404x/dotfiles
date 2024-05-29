{ ... }:

{

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  # Nix features config  
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];    
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

}
