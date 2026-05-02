{
  llm-agents,
  jail,
  daveShield,
  skill-issues-src,
  stdenv,
  symlinkJoin,
  makeWrapper,
}:
let
  skillIssues = stdenv.mkDerivation {
    name = "skill-issues";
    version = "0.1";
    src = skill-issues-src;
    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    installPhase = ''
      mkdir -p $out
      cp -r ./agents ./skills $out
    '';
  };
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
  ];
  openCodeExtraCombinators = with jail.combinators; [
    # share the opencode config from my home dir.
    # otherwise, you have to configure and auth in each new sandbox environment.
    (readwrite (noescape "~/.config/opencode"))
    (readwrite (noescape "~/.local/share/opencode"))
    (readwrite (noescape "~/.local/state/opencode"))
    # bind the managed AGENTS.md file into the sandbox environment.
    (ro-bind "${configDir}/config/AGENTS.md" (noescape "~/.config/opencode/AGENTS.md"))
    # bind skill-issues agents and skill files
    (try-ro-bind "${skillIssues}" (noescape "~/.config/opencode/skills/skill-issues"))
    (try-ro-bind "${skillIssues}/agents" (noescape "~/.config/opencode/agents/skill-issues"))
  ];
  wrappedOpenCode = symlinkJoin {
    name = "opencode";
    paths = [
      llm-agents.opencode
      configDir
      skillIssues
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
        ++ (map (d: jail.combinators.readwrite (jail.combinators.noescape d)) extraDirs);
    };
in
{
  lib = {
    makeJailedOpenCode = makeJailedOpenCode;
  };
  packages = {
    jailedOpenCode = makeJailedOpenCode { };
    unjailedOpenCode = wrappedOpenCode;
  };
}
