{ config, lib, pkgs, ... }:

let
  night-light = pkgs.writeShellScriptBin "night-light"
  ''
    #!/usr/bin/env bash

    if pgrep -x hyprsunset >/dev/null; then
      pkill -x hyprsunset
      notify-send "🌞 Nightlight Disabled" "Brightness and color restored"
    else
      hyprsunset --temperature 4500 --gamma 85 &
      notify-send "🌙 Nightlight Enabled" "Warm color and lower brightness applied"
    fi
  '';
in
{
  home.packages = with pkgs; [
    dunst
    hyprsunset
    night-light
  ];
}

