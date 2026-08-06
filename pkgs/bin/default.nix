{ pkgs, ... }:

{
  nix-install = pkgs.writeShellApplication {
    name = "nix-install";
    runtimeInputs = with pkgs; [
      gum
      jq
      git
    ];
    text = builtins.readFile ./nix-install.sh;
  };

  gamerun = pkgs.writeShellApplication {
    name = "gamerun";
    runtimeInputs = with pkgs; [
      ryzenadj
      gamemode
    ];
    text = builtins.readFile ./gamerun.sh;
  };

  mc-bak = pkgs.writeShellApplication {
    name = "mc-bak";
    runtimeInputs = with pkgs; [
      ncurses
      zstd
      pv
    ];
    text = builtins.readFile ./mc-bak.sh;
  };

}
