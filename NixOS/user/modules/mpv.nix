{ pkgs, ... }:

{
  programs.mpv = {
    enable = true;

    config = {
      profile = "gpu-hq";
      hwdec = "auto-safe";
      ytdl-format = "bestvideo[height<=1080]+bestaudio/best";

      # ui
      osc = "no";
      osd-bar = "no";
      border = "no";
    };

    package = pkgs.mpv.override {
      scripts = with pkgs.mpvScripts; [
        uosc
        thumbfast
        webtorrent-mpv-hook
        mpv-cheatsheet-ng
      ];
    };

    bindings = {
      "menu" = "script-binding uosc/menu";
      "MBTN_RIGHT" = "script-binding uosc/menu";
      "S" = "script-binding uosc/subtitles";
      "A" = "script-binding uosc/audio";
      "P" = "script-binding uosc/playlist";
      "C" = "script-binding uosc/chapters";
    };
  };

  # in-terminal yt
  programs.fish.shellAliases = {
    yt = "mpv 'ytdl://ytsearch1:'$argv";
  };

  home.packages = with pkgs; [
    yt-dlp
    nodejs
    ff2mpv
  ];
}
