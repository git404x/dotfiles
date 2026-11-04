{
  pkgs,
  ...
}:
{
  stylix.targets.zen-browser.profileNames = [ "default" ];

  programs.zen-browser = {
    enable = true;
    nativeMessagingHosts = [ pkgs.ff2mpv ];

    extensions = [
      {
        slug = "bitwarden-password-manager";
        id = "{446900e4-71c2-419f-a6a7-df9c091e268b}";
        privateBrowsing = true;
      }
      {
        slug = "ublock-origin";
        id = "uBlock0@raymondhill.net";
        privateBrowsing = true;
      }
      {
        slug = "tampermonkey";
        id = "firefox@tampermonkey.net";
        privateBrowsing = false;
      }
    ];

    profiles.default = {
      name = "default";
      id = 0;
      isDefault = true;

      bookmarks = {
        force = true;
        settings = [
          {
            keyword = "gh";
            name = "GitHub";
            url = "https://github.com";
          }
          {
            keyword = "yt";
            name = "YouTube";
            url = "https://youtube.com";
          }
        ];
      };

      search = {
        force = true;
        default = "google";
        engines = {
          "GitHub" = {
            urls = [ { template = "https://github.com/search?q={searchTerms}"; } ];
            definedAliases = [ "gh" ];
          };
          "Home Manager" = {
            urls = [
              { template = "https://home-manager-options.extranix.com?query={searchTerms}&release=master"; }
            ];
            definedAliases = [ "hm" ];
          };
          "NixOS Packages" = {
            urls = [ { template = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}"; } ];
            definedAliases = [ "np" ];
          };
          "NixOS Options" = {
            urls = [ { template = "https://search.nixos.org/options?channel=unstable&query={searchTerms}"; } ];
            definedAliases = [ "no" ];
          };
          "NixOS Wiki" = {
            urls = [ { template = "https://wiki.nixos.org/w/index.php?search={searchTerms}"; } ];
            definedAliases = [ "nw" ];
          };
        };
      };

      settings = {
        "zen.welcome-screen.seen" = true;
        "zen.view.experimental-no-window-controls" = true;
        "dom.security.https_only_mode" = true;
        "browser.search.separatePrivateDefault" = false;
        "network.trr.mode" = 3;
        "network.trr.uri" = "https://cloudflare-dns.com/dns-query";
        "extensions.formautofill.creditCards.enabled" = false;
        "signon.rememberSignons" = false;
      };
    };
  };
}
