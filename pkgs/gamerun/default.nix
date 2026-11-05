{
  lib,
  stdenv,
  makeWrapper,
  jq,
  procps,
  ryzenadj,
  gamemode,
  util-linux,
  coreutils,
  bash,
}:

stdenv.mkDerivation rec {
  pname = "gamerun";
  version = "1.3.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 src/main.sh $out/bin/gamerun
    install -Dm644 profiles.json $out/share/gamerun/profiles.json

    mkdir -p $out/lib/gamerun
    install -Dm644 src/config.sh $out/lib/gamerun/config.sh
    install -Dm644 src/power.sh $out/lib/gamerun/power.sh
    install -Dm644 src/launch.sh $out/lib/gamerun/launch.sh
    install -Dm644 src/bench.sh $out/lib/gamerun/bench.sh

    wrapProgram $out/bin/gamerun \
      --set GAMERUN_BIN "$out/bin/gamerun" \
      --set GAMERUN_LIB_DIR "$out/lib/gamerun" \
      --set GAMERUN_DATA_DIR "$out/share/gamerun" \
      --set GAMERUN_VERSION "${version}" \
      --prefix PATH : ${
        lib.makeBinPath [
          jq
          procps
          ryzenadj
          gamemode
          util-linux
          coreutils
          bash
        ]
      }

    runHook postInstall
  '';

  meta = with lib; {
    description = "AMD APU power governor, watchdog enforcer, and game launcher";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "gamerun";
  };
}
