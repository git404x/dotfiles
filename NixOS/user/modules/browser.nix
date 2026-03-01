{ config, pkgs, ... }:
{

  programs.chromium = {
    enable = true;
    package = pkgs.ungoogled-chromium;
    extensions = [
    {
      # web store shim
      id = "ocaahdebbfolfmndjeplogmgcagdmblk";
      version = "1.5.5.2";
      crxPath = builtins.fetchurl {
        url = "https://github.com/NeverDecaf/chromium-web-store/releases/download/v1.5.5.2/Chromium.Web.Store.crx";
        sha256 = "0fm5qz4gkn8z2chwlk0j1ngwgpadw2vyb56h8ifcfij0qziiyn09";
      };
    }
    ];
    commandLineArgs = [
      "--extension-mime-request-handling=always-prompt-for-install"
      "--disable-features=PasswordManager,CredentialManager,AutofillAddressEnabled,AutofillCreditCardEnabled,OnDeviceHeadSuggest,MediaRouter"
      "--disable-save-password-bubble"
      "--password-store=basic"
      "--no-default-browser-check"
      "--no-first-run"
      "--disable-search-engine-collection"
      "--disable-sync"
      "--disable-speech-api"
      "--disable-reading-from-canvas"
      "--no-pings"
    ];
  };
}
