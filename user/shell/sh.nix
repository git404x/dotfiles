{ pkgs, ... }:

let

  # shell aliases
  shAliases = {
    ls = "eza --icons -l -T -L=1";
    ll = "ls -l";
    flake-update = "nix flake update";
    nix-switch = "sudo nixos-rebuild switch --flake ~/dotfiles";
    home-switch = "home-manager switch --flake ~dotfiles";
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
