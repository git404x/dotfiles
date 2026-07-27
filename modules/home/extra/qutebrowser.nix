{ ... }:

{
  programs.qutebrowser = {
    enable = true;
    settings = {
      # UI
      colors.webpage.preferred_color_scheme = "dark";
      scrolling.smooth = true;
      tabs.position = "top";
      tabs.show = "multiple"; # show tab bar on multiple tabs
      # privacy
      content.cookies.accept = "no-3rdparty";
      content.webrtc_ip_handling_policy = "default-public-interface-only";
    };

    searchEngines = {
      DEFAULT = "https://duckduckgo.com/?q={}";
      g = "https://google.com/search?q={}";
      nw = "https://wiki.nixos.org/w/index.php?search={}";
      np = "https://search.nixos.org/packages?channel=unstable&query={}";
      no = "https://search.nixos.org/options?channel=unstable&query={}";
      hm = "https://home-manager-options.extranix.com?query={}";
      gh = "https://github.com/search?q={}";
    };

    keyBindings = {
      normal = {
        "J" = "tab-prev";
        "K" = "tab-next";
        "xb" = "config-cycle statusbar.show always never";
        "xt" = "config-cycle tabs.show always never";
      };
    };
  };
}
