{ pkgs, ... }:

{
  ytdl = pkgs.writeShellApplication {
    name = "ytdl";
    runtimeInputs = with pkgs; [
      yt-dlp
      fzf
    ];
    text = builtins.readFile ./ytdl.sh;
  };

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

  ai-cli = pkgs.writers.writePython3Bin "ai-cli" {
    libraries = [ ];
    makeWrapperArgs = [
      "--prefix"
      "PATH"
      ":"
      "${pkgs.lib.makeBinPath (
        with pkgs;
        [
          fzf
          litellm
        ]
      )}"
    ];
  } (builtins.readFile ./ai-cli.py);

}
