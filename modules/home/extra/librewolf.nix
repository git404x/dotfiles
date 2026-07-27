{ ... }:

{

  stylix.targets.librewolf.profileNames = [ "default" ];
  programs.librewolf = {
    enable = true;
    profiles = {
      default = {
        id = 0;
        isDefault = true;
        path = "default";

        settings = {
          "signon.rememberSignons" = false;
          "browser.send_pings" = false;
          "browser.send_pings.require_same_host" = true;
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "privacy.donottrackheader.enabled" = true;
        };
      };
    };
  };
}
