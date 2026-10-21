{
  lib,
  stdenvNoCC,
  makeWrapper,
  python3,
  gobject-introspection,
  gst_all_1,
  bash,
  coreutils,
  findutils,
  gnused,
  socat,
  jq,
  fuzzel,
  libnotify,
  v4l-utils,
  systemd,
  ffmpeg,
  pulseaudio,
  pipewire,
  kmod,
  psmisc,
}:

let
  py = python3.withPackages (ps: [ ps.pygobject3 ]);

  gstPlugins = with gst_all_1; [
    gstreamer
    gst-plugins-base # videoconvert, videoscale, videotestsrc, clocksync
    gst-plugins-good # v4l2src, v4l2sink, jpegdec, videorate
    gst-plugins-bad
    gst-libav # decodebin fallbacks (h264/hevc in mp4/mkv)
  ];

  gstPluginPath = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" gstPlugins;

  ctlPath = lib.makeBinPath [
    bash
    coreutils
    findutils
    gnused
    socat
    jq
    fuzzel
    libnotify
    v4l-utils
    systemd
    ffmpeg
    pulseaudio
    pipewire
    kmod
    psmisc
  ];
in
stdenvNoCC.mkDerivation {
  pname = "vcam";
  version = "0.1.0";
  src = ./.;

  nativeBuildInputs = [
    makeWrapper
    gobject-introspection # sets up GI_TYPELIB_PATH for the wrappers below
  ];

  buildInputs = [ py ] ++ gstPlugins;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 vcamd.py $out/bin/vcamd
    install -Dm755 vcam-toggle.sh $out/bin/vcam-toggle
    install -Dm755 vcam-hw.sh $out/bin/vcam-hw

    substituteInPlace $out/bin/vcamd \
      --replace-fail "#!/usr/bin/env python3" "#!${py}/bin/python3"
    substituteInPlace $out/bin/vcam-toggle \
      --replace-fail "#!/usr/bin/env bash" "#!${bash}/bin/bash"
    substituteInPlace $out/bin/vcam-hw \
      --replace-fail "#!/usr/bin/env bash" "#!${bash}/bin/bash"

    wrapProgram $out/bin/vcamd \
      --prefix GI_TYPELIB_PATH : "$GI_TYPELIB_PATH" \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${gstPluginPath}"

    wrapProgram $out/bin/vcam-toggle \
      --prefix PATH : "${ctlPath}"

    wrapProgram $out/bin/vcam-hw \
      --prefix PATH : "${ctlPath}"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Seamless v4l2loopback virtual webcam daemon + CLI";
    platforms = platforms.linux;
    mainProgram = "vcam-toggle";
    license = licenses.mit;
  };
}
