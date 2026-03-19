{ pkgs }:

let
  jdownloader-script = pkgs.writeShellApplication {
    name = "jdownloader";
    runtimeInputs = [ pkgs.jre pkgs.wget ];
    text = ''
      export _JAVA_AWT_WM_NONREPARENTING=1

      JD_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/jdownloader-isolated"
      JAR_URL="http://installer.jdownloader.org/JDownloader.jar"

      mkdir -p "$JD_DIR"
      cd "$JD_DIR"

      # Fetch the clean jar if it doesn't exist
      if [ ! -f "JDownloader.jar" ]; then
          echo "Initializing JDownloader core..."
          wget -qO JDownloader.jar "$JAR_URL"
      fi

      # Execute within the isolated environment
      exec java -jar JDownloader.jar
    '';
  };

  desktop-item = pkgs.makeDesktopItem {
    name = "JDownloader";
    desktopName = "JDownloader";
    exec = "jdownloader";
    icon = "jdownloader";
    categories = [ "Network" "FileTransfer" ];
    comment = "Clean, isolated JDownloader instance";
  };

in

pkgs.runCommand "jdownloader" {} ''
  mkdir -p $out/bin $out/share/applications
  ln -s ${jdownloader-script}/bin/jdownloader $out/bin/jdownloader
  ln -s ${desktop-item}/share/applications/* $out/share/applications/

  mkdir -p $out/share/pixmaps $out/share/icons/hicolor/scalable/apps
  cp ${./icon.svg} $out/share/pixmaps/jdownloader.svg
  cp ${./icon.svg} $out/share/icons/hicolor/scalable/apps/jdownloader.svg
''
