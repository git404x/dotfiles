  let
    nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
    pkgs = import nixpkgs { config = {}; overlays = []; };

  in

    pkgs.mkShellNoCC { 
      packages = with pkgs; [
        figlet
        lolcat
        libgcc
        gcc
        yarn
        ripgrep
        rustup
        cargo
        cmake
        nodejs_latest
        python3
        gnumake
      ];

    GREETING = "nix shell env !!";

    shellHook = ''
      echo $GREETING | figlet | lolcat
    '';

    }

