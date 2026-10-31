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
  version = "1.2.0";
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
    install -Dm755 src/vcam-test $out/bin/vcam-test
    install -Dm755 src/vcam-hw $out/bin/vcam-hw
    install -Dm755 vcam.sh $out/bin/vcam
    install -Dm644 index.html $out/share/vcam/index.html

    mkdir -p $out/share/polkit-1/actions
    substitute vcam.policy $out/share/polkit-1/actions/vcam.policy \
      --subst-var out

    wrapProgram $out/bin/vcamd \
      --prefix PATH : "${binPath}"

    wrapProgram $out/bin/vcam-test \
      --prefix PATH : "${binPath}:$out/bin"

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
