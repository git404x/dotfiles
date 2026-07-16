{ pkgs, ... }:

{
  programs.chromium = {
    enable = true;
    package = pkgs.ungoogled-chromium;
    commandLineArgs = [
      # Disable internal credential, payment, and identity hooks
      "--disable-features=PasswordManager,CredentialManager,AutofillAddressEnabled,AutofillCreditCardEnabled,MediaRouter"
      "--disable-save-password-bubble"
      "--password-store=basic"

      # privacy, telemetry, and background API mitigation
      "--disable-search-engine-collection"
      "--disable-sync"
      "--disable-speech-api"
      "--disable-reading-from-canvas"
      "--no-pings"

      # UX strictness
      "--no-default-browser-check"
      "--extension-mime-request-handling=always-prompt-for-install"
    ];
    extensions = [
      {
        # web store shim
        id = "ocaahdebbfolfmndjeplogmgcagdmblk";
        version = "1.5.5.3";
        crxPath = builtins.fetchurl {
          url = "https://github.com/NeverDecaf/chromium-web-store/releases/download/v1.5.5.3/Chromium.Web.Store.crx";
          sha256 = "0fm5qz4gkn8z2chwlk0j1ngwgpadw2vyb56h8ifcfij0qziiyn09";
        };
      }
      # uBlock Origin
      {
        id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";
        updateUrl = "https://clients2.google.com/service/update2/crx";
      }
      # Bitwarden
      {
        id = "nngceckbapebfimnlniiiahkandclblb";
        updateUrl = "https://clients2.google.com/service/update2/crx";
      }
    ];

  };
}
