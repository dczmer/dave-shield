{
  llm-agents,
  jail,
  daveShield,
  rtk,
  stdenv,
  symlinkJoin,
  makeWrapper,
}:
let
  configDir = stdenv.mkDerivation {
    name = "Jailed Opencode Config";
    version = "0.1";
    src = ./config;
    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    installPhase = ''
      mkdir -p $out/config
      cp -rv ./* $out/config
    '';
  };
  openCodeExtraPkgs = [
    rtk
  ];
  openCodeExtraCombinators = with jail.combinators; [
    # share the opencode config from my home dir.
    # otherwise, you have to configure and auth in each new sandbox environment.
    (readwrite (noescape "~/.config/opencode"))
    (readwrite (noescape "~/.local/share/opencode"))
    (readwrite (noescape "~/.local/state/opencode"))
    (ro-bind "${configDir}/config/AGENTS.md" (noescape "~/.config/opencode/AGENTS.md"))
  ];
  wrappedOpenCode = symlinkJoin {
    name = "opencode";
    paths = [
      llm-agents.opencode
      configDir
    ];
    buildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/opencode \
        --set OPENCODE_CONFIG $out/config/opencode.jsonc \
        --set OPENCODE_TUI_CONFIG $out/config/tui.jsonc
    '';
    meta = {
      mainProgram = "opencode";
    };
  };
  makeJailedOpenCode =
    {
      extraPkgs ? [ ],
      extraDirs ? [ ],
      extraCombinators ? [ ],
    }:
    daveShield {
      exec = wrappedOpenCode;
      extraPkgs = extraPkgs ++ openCodeExtraPkgs;
      extraCombinators =
        extraCombinators
        ++ openCodeExtraCombinators
        ++ (builtins.map (d: jail.combinators.readwrite (jail.combinators.noescape d)) extraDirs);
    };
in
{
  lib = {
    makeJailedOpenCode = makeJailedOpenCode;
  };
  packages = {
    jailedOpenCode = makeJailedOpenCode { };
  };
}
