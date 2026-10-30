{
  lib,
  stdenv,
  pkg-config,
  makeWrapper,
  glib,
  gst_all_1,
  pipewire,
  ffmpeg,
  socat,
  jq,
  fuzzel,
  libnotify,
  kmod,
  psmisc,
  coreutils,
  findutils,
  gnugrep,
  systemd,
}:

let
  gstPlugins = with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-libav
  ];

  gstPluginPath = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" gstPlugins;

  binPath = lib.makeBinPath [
    pipewire
    ffmpeg
    socat
    jq
    fuzzel
    libnotify
    kmod
    psmisc
    coreutils
    findutils
    gnugrep
    systemd
  ];
in
stdenv.mkDerivation {
  pname = "vcam";
  version = "1.0.0";
  src = ./.;

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    glib
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
  ] ++ gstPlugins;

  buildPhase = ''
    runHook preBuild
    make -C src
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 src/vcamd $out/bin/vcamd
    install -Dm755 vcam.sh $out/bin/vcam

    wrapProgram $out/bin/vcamd \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${gstPluginPath}"

    wrapProgram $out/bin/vcam \
      --prefix PATH : "${binPath}:$out/bin" \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${gstPluginPath}"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Virtual webcam and privacy microphone suite";
    platforms = platforms.linux;
    mainProgram = "vcam";
  };
}
