{
  lib,
  stdenv,
  makeWrapper,
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
    makeWrapper
  ];

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
      --prefix PATH : "${binPath}"

    wrapProgram $out/bin/vcam \
      --prefix PATH : "${binPath}:$out/bin"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Virtual webcam and privacy microphone suite";
    platforms = platforms.linux;
    mainProgram = "vcam";
  };
}
