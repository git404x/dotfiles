{ ... }:

{
  programs.lazygit = {
    enable = true;
    settings = {
      confirmOnQuit = false;
      git.autoFetch = false;
    };
  };
}
