{ pkgs, ... }:

{
  gamerun = pkgs.writeShellApplication {
    name = "gamerun";
    runtimeInputs = with pkgs; [
      coreutils
      pciutils
      gnugrep
      gawk
      gnused
    ];
    text = builtins.readFile ./gamerun.sh;
  };

  mc-bak = pkgs.writeShellApplication {
    name = "mc-bak";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      gnutar
      zstd
      ncurses
      pv
    ];
    text = builtins.readFile ./mc-bak.sh;
  };

  flux-compiler = pkgs.writeShellApplication {
    name = "fluxc";
    runtimeInputs = with pkgs; [
      packwiz
      mrpack-install
      zip
      jq
      coreutils
      ncurses
    ];
    text = builtins.readFile ./mc-pack.sh;
  };

}
