{
  pkgs,
  pkgs-stable,
  ...
}:

{

  # system pkgs
  environment.systemPackages =
    (with pkgs; [
      # core tools
      axel
      curl
      wget
      dig
      vim
      nano
      nanorc
      zip
      unzip
      p7zip
      unrar
      parallel
      jq
      openssh

      # system
      usbutils
      pciutils
      lshw
      lm_sensors
      parted
      gparted
      cryptsetup
      gnome-disk-utility
      ntfs3g
      os-prober
      htop
      btop
      killall

      # dev
      git
      git-filter-repo
      gh
      glab
      lazygit
      vscodium
      neovim
      neovide

      # terminal
      tmux
      tmate
      yazi
      foot

      # utilities
      yt-dlp
      android-tools
      ffmpeg
      ani-cli
      mpv
      imv
      loupe
      tectonic

      # applications
      obsidian
      librewolf
      zen-browser
      telegram-desktop
      onlyoffice-desktopeditors
      stirling-pdf-desktop
      gimp
      proton-vpn
      qbittorrent
      antigravity

    ])
    ++ (with pkgs-stable; [
      # pkgs-stable
    ]);

}
