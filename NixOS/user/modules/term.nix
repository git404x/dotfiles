{ pkgs, ... }:
{
  programs.foot = {
    enable = true;
    server.enable = true;
    settings = {
      main = {
        pad = "8x8";
        term = "xterm-256color";
      };
      scrollback = {
        lines = 10000;
      };
      mouse = {
        hide-when-typing = "yes";
      };
    };
  };
}
