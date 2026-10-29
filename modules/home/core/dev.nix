{
  dotfiles,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    opencode
    antigravity-cli

    uv
    nodejs
    bun
  ];
}
