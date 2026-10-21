{
  dotfiles,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    opencode
    antigravity-cli
    # antigravity-ide
    # claude-code
    # cursor-cli
    # codex
    # kiro
    # kiro-cli

    uv
    nodejs
    bun
  ];
}
