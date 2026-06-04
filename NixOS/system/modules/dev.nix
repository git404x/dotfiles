{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # agent
    antigravity
    antigravity-cli
    code-cursor
    cursor-cli
    claude-code
    claude-monitor

    # utils
    pandoc
    poppler-utils
    tectonic
    ripgrep
    jq
    fd
    uv
    (python3.withPackages (
      ps: with ps; [
        pip
        markitdown
        requests
      ]
    ))

    # compilers
    javaPackages.compiler.openjdk25
    python3
    nodejs

    # dependencies
    markitdown-mcp

  ];

}
