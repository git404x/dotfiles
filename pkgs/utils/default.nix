{ pkgs, ... }:

{
  start-polkit-agent = pkgs.writeShellApplication {
    name = "start-polkit-agent";
    text = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
  };

  cam-toggle = pkgs.writeShellApplication {
    name = "cam-toggle";
    runtimeInputs = with pkgs; [ kmod psmisc libnotify systemd ];
    text = builtins.readFile ./cam-toggle.sh;
  };

  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = with pkgs; [ grim slurp wl-clipboard libnotify swappy ];
    text = builtins.readFile ./screenshot.sh;
  };

  record-screen = pkgs.writeShellApplication {
    name = "record-screen";
    runtimeInputs = with pkgs; [ pulseaudio procps libnotify wl-screenrec slurp ];
    text = builtins.readFile ./record-screen.sh;
  };

  clipboard = pkgs.writeShellApplication {
    name = "clipboard";
    runtimeInputs = with pkgs; [ cliphist fuzzel wl-clipboard libnotify ];
    text = builtins.readFile ./clipboard.sh;
  };

  powermenu = pkgs.writeShellApplication {
    name = "powermenu";
    runtimeInputs = with pkgs; [ fuzzel hyprlock systemd ];
    text = builtins.readFile ./powermenu.sh;
  };
}
