{ pkgs, ... }:

let
  tools = {
    start-polkit-agent = pkgs.writeShellApplication {
      name = "start-polkit-agent";
      text = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
    };

    screenshot = pkgs.writeShellApplication {
      name = "screenshot";
      runtimeInputs = with pkgs; [
        grim
        slurp
        wl-clipboard
        libnotify
        swappy
        procps
        coreutils
      ];
      text = builtins.readFile ./screenshot.sh;
    };

    record-screen = pkgs.writeShellApplication {
      name = "record-screen";
      runtimeInputs = with pkgs; [
        pulseaudio
        procps
        libnotify
        wl-screenrec
        slurp
        coreutils
      ];
      text = builtins.readFile ./record-screen.sh;
    };

    clipboard = pkgs.writeShellApplication {
      name = "clipboard";
      runtimeInputs = with pkgs; [
        cliphist
        fuzzel
        wl-clipboard
        libnotify
        procps
        coreutils
      ];
      text = builtins.readFile ./clipboard.sh;
    };

    powermenu = pkgs.writeShellApplication {
      name = "powermenu";
      runtimeInputs = with pkgs; [
        fuzzel
        hyprlock
        systemd
      ];
      text = builtins.readFile ./powermenu.sh;
    };

    cage-run = pkgs.writeShellApplication {
      name = "cage-run";
      runtimeInputs = with pkgs; [
        cage
        fuzzel
      ];
      text = builtins.readFile ./cage-run.sh;
    };
  };
in
(pkgs.symlinkJoin {
  name = "sysutils";
  paths = builtins.attrValues tools;
})
// tools
