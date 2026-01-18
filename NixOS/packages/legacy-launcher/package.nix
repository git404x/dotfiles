{ lib
, stdenv
, fetchurl
, makeWrapper
, makeDesktopItem
, copyDesktopItems
, jre
, xorg
, libGL
, libpulseaudio
, udev
, flite
, vulkan-loader
}:

stdenv.mkDerivation rec {
  pname = "legacy-launcher";
  version = "latest";

  src = fetchurl {
    url = "https://dl.llaun.ch/legacy/bootstrap";
    sha256 = "sha256-a7bkm0ssu1/95hg0jlUxoBJFb6qVohQNcs1kLlRrc/4=";
    name = "LegacyLauncher_legacy.jar";
  };

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper copyDesktopItems ];

  desktopItems = [
    (makeDesktopItem {
     name = "legacy-launcher";
     desktopName = "Legacy Launcher";
     exec = "legacy-launcher";
     icon = "${./legacy-launcher.png}";
     categories = [ "Game" ];
     comment = "Stable, fast and simple Minecraft Launcher.";
     })
  ];

  # These are the runtime libraries Minecraft needs to "see"
  runtimeLibs = [
    xorg.libX11
    xorg.libXext
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXxf86vm
    libGL
    libpulseaudio
    udev
    flite
    vulkan-loader
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/legacy-launcher $out/share/pixmaps

    # Install the JAR
    cp $src $out/share/legacy-launcher/LegacyLauncher_legacy.jar

    # Install the Icon (We assume legacy-launcher.png is next to this file)
    cp ${./legacy-launcher.png} $out/share/pixmaps/legacy-launcher.png

    # use makeLibraryPath to turn the list of libs into a folder string
    # Then we inject it into LD_LIBRARY_PATH
    makeWrapper ${jre}/bin/java $out/bin/legacy-launcher \
      --add-flags "-jar $out/share/legacy-launcher/LegacyLauncher_legacy.jar" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}"

    # Install the desktop item generated above
    copyDesktopItems

    runHook postInstall
  '';

  meta = with lib; {
    description = "Stable, fast and simple Minecraft Launcher";
    homepage = "https://llaun.ch";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ ];
    platforms = platforms.all;
  };
}
