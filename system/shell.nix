  let
    nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-24.05";
    pkgs = import nixpkgs { config = {}; overlays = []; };

  in

    pkgs.mkShellNoCC { 
      packages = with pkgs; [
        cowsay
        lolcat
        libgcc
        yarn
        ripgrep
        rustup
        cargo
        cmake
        nodePackages.nodejs
        nodePackages.npm
        python3
        gnumake
      ];

    GREETING = "Welcome to shell env !";

    shellHook = ''
      echo $GREETING | cowsay | lolcat
    '';

    }

