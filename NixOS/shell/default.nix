  let
    nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
    pkgs = import nixpkgs { config = {}; overlays = []; };

  in

    pkgs.mkShellNoCC { 
      packages = with pkgs; [
        figlet
        lolcat
        cargo
        fd
        gcc
        gnumake
        go
        libgcc
        nodePackages_latest.nodejs
        openjdk
        python3
        ripgrep
        ruby
        rustup
        yarn
      ];

    GREETING = "nix shell env !!";

    shellHook = ''
      echo $GREETING | figlet | lolcat
    '';

    }

