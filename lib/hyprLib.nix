{ lib }:
let
  inline = lib.generators.mkLuaInline;
in
config:
let
  compiledLocals = lib.mapAttrs (k: v: { _var = v; }) (config.locals or { });

  compiledEnv = lib.mapAttrsToList (k: v: { _args = [ k (toString v) ]; }) (config.env or { });

  compiledOn = lib.optionalAttrs (config ? onStart) {
    _args = [
      "hyprland.start"
      (inline ''
        function()
          ${lib.concatMapStringsSep "\n          " (cmd: ''hl.exec_cmd("${cmd}")'') config.onStart}
        end
      '')
    ];
  };

  compiledCurves = map (def: {
    _args = [
      (builtins.elemAt def 0)
      {
        type = "bezier";
        points = [ [ (builtins.elemAt def 1) (builtins.elemAt def 2) ] [ (builtins.elemAt def 3) (builtins.elemAt def 4) ] ];
      }
    ];
  }) (config.curve or [ ]);

  compiledAnimations = map (def:
    let
      l = builtins.length def;
      style = if l > 4 then builtins.elemAt def 4 else "";
    in
    {
      leaf = builtins.elemAt def 0;
      enabled = builtins.elemAt def 1;
      speed = builtins.elemAt def 2;
      bezier = builtins.elemAt def 3;
    } // lib.optionalAttrs (style != "") { inherit style; }
  ) (config.animation or [ ]);

  compiledWsBinds =
    if config ? workspaces then
      lib.concatMap (i:
        let
          k = if i == 10 then "0" else toString i;
          w = toString i;
        in
        [
          [ config.workspaces.bind k "focus({ workspace = ${w} })" ]
          [ config.workspaces.move k "window.move({ workspace = ${w} })" ]
        ]
      ) (lib.range 1 (config.workspaces.count or 10))
    else
      [ ];

  rawBinds = (config.bind or [ ]) ++ compiledWsBinds;
  compiledBinds = map (def:
    let
      l = builtins.length def;
      mod = builtins.elemAt def 0;
      key = builtins.elemAt def 1;
      cmd = builtins.elemAt def 2;
      opts = if l > 3 then builtins.elemAt def 3 else { };
      comboStr = if mod == "" then ''"${key}"'' else ''${mod} .. " + ${key}"'';
    in
    {
      _args = [ (inline comboStr) (inline "hl.dsp.${cmd}") ] ++ lib.optional (opts != { }) opts;
    }
  ) rawBinds;

  cleanConfig = builtins.removeAttrs config [ 
    "locals" "onStart" "env" "layer_rule" "window_rule" "bind" "workspaces" 
    "curve" "monitor" "device" "animation" "gesture"
  ];

in
cleanConfig
// lib.optionalAttrs (config ? monitor) { inherit (config) monitor; }
// lib.optionalAttrs (config ? device) { inherit (config) device; }
// lib.optionalAttrs (config ? gesture) { inherit (config) gesture; }
// lib.optionalAttrs (config ? curve) { curve = compiledCurves; }
// lib.optionalAttrs (config ? layer_rule) { inherit (config) layer_rule; }
// lib.optionalAttrs (config ? window_rule) { inherit (config) window_rule; }
// lib.optionalAttrs (config ? animation) { animation = compiledAnimations; }
// lib.optionalAttrs (rawBinds != [ ]) { bind = compiledBinds; }
// lib.optionalAttrs (config ? onStart) { on = compiledOn; }
// lib.optionalAttrs (config ? env) { env = compiledEnv; }
// compiledLocals
