{ lib
, stdenv
, fetchurl
, makeWrapper
, makeDesktopItem
, copyDesktopItems
  # runtime dependencies
, jre
, xorg
, libGL
, libpulseaudio
, pipewire
, libjack2
, alsa-lib
, udev
, flite
, vulkan-loader
, libusb1
, addDriverRunpath
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
      desktopName = "Minecraft: Legacy Launcher";
      exec = "legacy-launcher";
      icon = "legacy-launcher";
      categories = [ "Game" ];
      comment = "Stable, fast and simple Minecraft Launcher.";
    })
  ];

  # runtime libraries to fix NixOS linking errors
  runtimeLibs = [
    xorg.libX11
    xorg.libXext
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXxf86vm

    # graphics
    libGL
    vulkan-loader # performance mods

    # audio stack
    libpulseaudio
    pipewire
    libjack2
    alsa-lib

    # input & controller
    udev
    libusb1
    flite
  ];

  installPhase = ''
    runHook preInstall

    # install .jar
    mkdir -p $out/bin $out/share/legacy-launcher
    cp $src $out/share/legacy-launcher/LegacyLauncher_legacy.jar

    # icon
    mkdir -p $out/share/pixmaps $out/share/icons/hicolor/scalable/apps
    cp ${./icon.svg} $out/share/pixmaps/legacy-launcher.svg
    cp ${./icon.svg} $out/share/icons/hicolor/scalable/apps/legacy-launcher.svg

    # wrapper script
    makeWrapper ${jre}/bin/java $out/bin/legacy-launcher \
      --add-flags "-jar $out/share/legacy-launcher/LegacyLauncher_legacy.jar" \
      --prefix LD_LIBRARY_PATH : "${addDriverRunpath.driverLink}/lib:${lib.makeLibraryPath runtimeLibs}"

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
