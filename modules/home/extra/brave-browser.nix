{ pkgs, inputs, ... }:

{
  imports = [ inputs.brave-browser.homeManagerModules.default ];

  programs.brave-browser = {
    enable = true;
    package = pkgs.brave-origin;
    extensions = [
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
      { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
    ];
    commandLineArgs = [
      "--disable-search-engine-collection"
      "--disable-sync"
      "--no-pings"
      "--disable-features=WebRtcAllowInputVolumeAdjustment,AutofillAddressEnabled,AutofillCreditCardEnabled"
      "--no-default-browser-check"
    ];
  };
}
