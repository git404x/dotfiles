{ userConfig, pkgs, ... }:

let

  # shell aliases
  shAliases = {

    # Helpful aliases
    c = "clear"; # clear terminal
    please = "sudo";
    doas = "sudo";
    dir = "dir --color=auto";
    jctl = "journalctl -p 3 -xb"; # get error msgs from journalctl
    cat = "bat --style full";

    # Replace ls with eza
    ls = "eza -al --color=always --group-directories-first --icons"; # preferred listing
    lsz= "eza -al --color=always --total-size --group-directories-first --icons"; # include file size
    la = "eza -a --color=always --group-directories-first --icons";  # all files and dirs
    ll = "eza -l --color=always --group-directories-first --icons";  # long format
    lt = "eza -aT --color=always --group-directories-first --icons"; # tree listing
    "l." = "eza -ald --color=always --group-directories-first --icons .*"; # show only dotfiles

    # Handy change dir shortcuts
    ".." = "cd ..";
    "..." = "cd ../..";
    ".2" = "cd ../..";
    ".3" = "cd ../../..";
    ".4" = "cd ../../../..";
    ".5" = "cd ../../../../..";

    # others
    ff = "fastfetch";
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
