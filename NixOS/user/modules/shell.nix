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
    nix-switch = "nh os switch ~/dotfiles";
    nix-switch-impure = "nh os switch ~/dotfiles --show-trace --impure --option --eval-cache false";
    home-switch = "nh home switch ~/dotfiles";
    nix-clean = "nh clean all";
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

    # nix helper
    nh = {
      enable = true;
      clean = {
        enable = true;
        dates = "weekly";
      };
    };
  };

  home.packages = with pkgs; [
    nh nvd nix-output-monitor
    fastfetch nitch onefetch
    bat eza
  ];

}
