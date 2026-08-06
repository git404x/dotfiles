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
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
    ];

  };
}
