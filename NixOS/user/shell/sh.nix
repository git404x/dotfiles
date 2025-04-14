{ userConfig, pkgs, ... }:

let

  # shell aliases
  shAliases = {

    # Helpful aliases
    c = "clear"; # clear terminal
    l = "eza -lh  --icons=auto"; # long list
    ls = "eza -1   --icons=auto"; # short list
    ll = "eza -lha --icons=auto --sort=name --group-directories-first"; # long list all
    ld = "eza -lhD --icons=auto"; # long list dirs

    # Handy change dir shortcuts
    ".." = "cd ..";
    "..." = "cd ../..";
    ".3" = "cd ../../..";
    ".4" = "cd ../../../..";
    ".5" = "cd ../../../../..";

    # others
    info = "fastfetch";
    fetch = "fastfetch";
    neofetch = "fastfetch";

    # nix related
    flake-update = "nix flake update";
    nix-switch = "sudo nixos-rebuild switch --flake ${userConfig.dotfilesDir}";
    nix-switch-impure = "sudo nixos-rebuild switch --flake ${userConfig.dotfilesDir} --show-trace --impure --option --eval-cache false";
    home-switch = "home-manager switch --flake ${userConfig.dotfilesDir}";
  };

in

{
  programs= {
    fish = {
      enable = true;
      shellAliases = shAliases;
    };

    bash = {
      enable = true;
      enableCompletion = true;
      shellAliases = shAliases;
    };

    starship = {
      enable = true;
      settings = {
        add_newline = true;
        line_break.disabled = true;
      };
    };

    direnv = {
      enable = true;
      # enableFishIntegration = true;
      nix-direnv.enable = true;
    };
  };

  home.packages = with pkgs; [
    nitch disfetch onefetch
    gnugrep gnused
    bat eza bottom fd bc
    direnv nix-direnv
  ];

}
