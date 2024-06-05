{ pkgs, ... }:

  # Create a package for kora-icons
  pkgs.stdenv.mkDerivation {
    name = "kora-icons";
 
    src = pkgs.fetchFromGitHub {
      owner = "bikass";
      repo = "kora";
      # url = "https://github.com/bikass/kora";
      rev = "0f0d48f7ef98f19732ac0dcb175954d8db32a18b";
      sha256 = "0aa8vr273xjv5c3sn18fbg6i736g9hv8dx77xa0izkzxd6a7j9dm";
    };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out
    cp -R ./* $out/
  '';

  }

