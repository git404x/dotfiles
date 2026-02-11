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
    grep = "rg";
    find = "fd";
    cd = "z";

    ls = "eza --icons --group-directories-first";
    ll = "eza -l --icons --group-directories-first";
    la = "eza -la --icons --group-directories-first";
    lt = "eza -aT --icons --group-directories-first";
    "l." = "eza -lad --icons --group-directories-first .*";

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

    # misc
    top = "htop";
    htop = "btop";

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
      interactiveShellInit = ''
        set fish_greeting # Disable the "Welcome to Fish" message
      '';
    };

    starship = {
      enable = true;
      settings = {
        add_newline = true;
        line_break.disabled = true;
      };
    };

    eza = {
      enable = true;
      icons = "auto";
      git = true;
    };

    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    fzf = {
      enable = true;
      enableFishIntegration = true;
    };

    bat = {
      enable = true;
      config = {
        pager = "less -FR";
      };
    };

    btop = {
      enable = true;
      settings = {
        vim_keys = true;
        update_ms = 500;
      };
    };

  };

  # nix helper
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      dates = "weekly";
    };
  };

  home.packages = with pkgs; [
    nh nvd nix-output-monitor
    fastfetch nitch onefetch
    fzf ripgrep
  ];

}
