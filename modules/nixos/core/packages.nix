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
      smartmontools
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
      gimp
      qbittorrent

      # engg
      nmap
      wireshark
      aircrack-ng
      ghidra
      frida-tools
      objection
      apktool
      apksigner
      jadx
      hashcat
      john

      # applications
      obsidian
      proton-vpn
      zathura
      stirling-pdf-desktop
      onlyoffice-desktopeditors
      telegram-desktop
      brave-origin
      qutebrowser
      librewolf
      zen-browser
      antigravity-cli
      antigravity-ide

    ])
    ++ (with pkgs-stable; [
      # pkgs-stable
    ]);

}
