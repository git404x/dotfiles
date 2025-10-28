{ pkgs, ... }:

let

  # shell aliases
  shAliases = {

    # basic aliases
    c = "clear";
    please = "sudo";
    doas = "sudo";
    dir = "dir --color=auto";
    jctl = "journalctl -p 3 -xb";
    cat = "bat --style full";

    # replace ls with eza
    ls = "eza -al --color=always --group-directories-first --icons";
    lsz= "eza -al --color=always --total-size --group-directories-first --icons";
    la = "eza -a --color=always --group-directories-first --icons";
    ll = "eza -l --color=always --group-directories-first --icons";
    lt = "eza -aT --color=always --group-directories-first --icons";
    "l." = "eza -ald --color=always --group-directories-first --icons .*";

    # handy change dir shortcuts
    ".." = "cd ..";
    "..." = "cd ../..";
    ".2" = "cd ../..";
    ".3" = "cd ../../..";
    ".4" = "cd ../../../..";
    ".5" = "cd ../../../../..";

    # fetch
    info = "nitch";
    fetch = "nitch";
    neofetch = "nitch";

    # nix related
    nix-flake-update = "nix flake update";
    nix-switch = "sudo nixos-rebuild switch --flake ~/dotfiles";
    nix-switch-impure = "sudo nixos-rebuild switch --flake ~/dotfiles --show-trace --impure --option --eval-cache false";
    home-switch = "home-manager switch --flake ~/dotfiles";
  };

in

{
  programs= {
    bash = {
      enable = true;
      enableCompletion = true;
      shellAliases = shAliases;
    };

    fish = {
      enable = true;
      shellAliases = shAliases;
    };

    starship = {
      enable = true;
      settings = {
        add_newline = true;
        line_break.disabled = true;
      };
    };
  };

  home.packages = with pkgs; [
    fastfetch nitch onefetch
    bat eza
  ];

}
