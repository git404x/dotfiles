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
    flake-update = "nix flake update";
    nix-switch = "sudo nixos-rebuild switch --flake ${userConfig.dotfilesDir}";
    home-switch = "home-manager switch --flake ${userConfig.dotfilesDir}";
  };

in

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    shellAliases = shAliases;

    history.size = 10000;
    # history.path = "${config.xdg.dataHome}/zsh/history";

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" ];
      theme = "agnoster";
    };
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = shAliases;
  };

  home.packages = with pkgs; [
    disfetch lolcat cowsay onefetch
    gnugrep gnused
    bat eza bottom fd bc
    direnv nix-direnv
  ];

  programs.direnv = { 
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

}
