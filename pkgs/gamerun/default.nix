{
  lib,
  stdenv,
  makeWrapper,
  ryzenadj,
  gamemode,
  util-linux,
  coreutils,
  bash,
}:

stdenv.mkDerivation {
  pname = "gamerun";
  version = "1.1.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 gamerun.sh $out/bin/gamerun
    install -Dm644 profiles.conf $out/share/gamerun/profiles.conf

    wrapProgram $out/bin/gamerun \
      --set GAMERUN_DATA_DIR "$out/share/gamerun" \
      --prefix PATH : ${
        lib.makeBinPath [
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
