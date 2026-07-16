{ pkgs, ... }:

let
  mpv-youtube-download = pkgs.stdenv.mkDerivation {
    pname = "mpv-youtube-download";
    version = "unstable";
    scriptName = "youtube-download.lua";
    src = pkgs.fetchFromGitHub {
      owner = "cvzi";
      repo = "mpv-youtube-download";
      rev = "d2c1eec49bec30995a446850fb10cd0b204aaf51";
      hash = "sha256-rB4KIFtNiCZFFSsI1H+m1kvhmeWfKMZ3q0AHgzyp59o=";
    };

    dontUnpack = false;

    installPhase = ''
      mkdir -p $out/share/mpv/scripts
      cp $src/youtube-download.lua $out/share/mpv/scripts/youtube-download.lua
    '';
  };
in
{
  programs.mpv = {
    enable = true;

    config = {
      # HW Tune
      vo = "gpu-next";
      gpu-api = "vulkan";
      hwdec = "auto-safe";
      hwdec-codecs = "all";

      # cache
      cache = "yes";
      demuxer-max-bytes = "150MiB";
      demuxer-max-back-bytes = "50MiB";

      # yt
      ytdl-format = "bestvideo[height<=1080][vcodec!=?av1]+bestaudio/best";
    };

    scriptOpts = {
      "youtube-download" = {
        # download_path = "~/Downloads";
        youtube_dl_exe = "yt-dlp";
        audio_format = "mp3";
        audio_quality = "0";
        # pop-up terminal progress
        open_new_terminal = false;
        open_new_terminal_timeout = "3";
      };
    };

    package = pkgs.mpv.override {
      scripts = with pkgs.mpvScripts; [
        mpris
        thumbfast
        webtorrent-mpv-hook
        mpv-cheatsheet-ng
        sponsorblock
        quality-menu
        mpv-youtube-download
      ];
    };

    bindings = {
      # Quality Switcher
      "Ctrl+f" = "script-binding quality_menu/video_formats";

      # yt-dl
      "Ctrl+d" = "script-message-to youtube_download download-video";
      "Ctrl+a" = "script-message-to youtube_download download-audio";
      "Ctrl+s" = "script-message-to youtube_download download-subtitle";
      "Ctrl+i" = "script-message-to youtube_download download-embed-subtitle";
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
