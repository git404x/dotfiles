{
  dotfiles,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    opencode
    antigravity-ide
    antigravity-cli
    claude-code
    cursor-cli
    codex
    kiro
    kiro-cli

    uv
    nodejs
    bun
  ];
}
