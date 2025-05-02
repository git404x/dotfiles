{ pkgs, ... }:

    # Create a package for fonts needed by rofi powermenu 
    pkgs.stdenv.mkDerivation {
      name = "extra-fonts";
        src = ~/dotfiles/user/fonts;
  
    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      cp -R ./*.tff $out/share/fonts/truetype/
    '';

    }
