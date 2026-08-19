{ pkgs, config, ... }:

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
    cd = "z";

    l = "eza --icons --group-directories-first";
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
    nix-switch = "nh os switch ~/dotfiles";
    nix-switch-impure = "nh os switch ~/dotfiles --show-trace --impure --option --eval-cache false";
    home-switch = "nh home switch ~/dotfiles";
    nix-clean = "nh clean all";
  };

in

{
  programs = {
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
        add_newline = false;
        package.disabled = true;
        line_break.disabled = true;
        command_timeout = 1000;
        git_branch = {
          symbol = " ";
        };
        git_status = {
          ignore_submodules = true;
        };
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

    direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
      config = {
        whitelist = {
          prefix = [
            "~/dotfiles"
            "~/dev"
          ];
        };
      };
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

  # aria2
  programs.aria2 = {
    enable = true;
    settings = {
      dir = "${config.home.homeDirectory}/Downloads";
      split = 4;
      max-connection-per-server = 4;
      file-allocation = "falloc";
      max-concurrent-downloads = 4;
      min-split-size = "5M";
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
    nh
    nvd
    nix-output-monitor
    nitch
    onefetch
    fzf
    ripgrep
    fd
    duf
    dust
  ];

}
