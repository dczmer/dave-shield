# TODO:
# - un-jailed version
# - document managing config files:
#   - `OPENCODE_CONFIG_DIR` will override/overlay ~/.config/opencode
#   - project-local opencode.json, .opencode dirs override those
#   - recommend: use `"*": "ask"` in main config, jailed config locks things down, per-project config makes adjustments as needed
#
# :( i think we have to manage these things manually:
# - how to make it pick up my custom skills and agents w/out write access to the store?
# - skill-issues
# - rtk, caveman, opencode-mem, superpowers
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
  openCodeExtraPkgs = [
    rtk
  ];
  openCodeExtraCombinators = with jail.combinators; [
    # share the opencode config from my home dir.
    # otherwise, you have to configure and auth in each new sandbox environment.
    (readwrite (noescape "~/.config/opencode"))
    (readwrite (noescape "~/.local/share/opencode"))
    (readwrite (noescape "~/.local/state/opencode"))
  ];
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
      extraCombinators ? [ ],
    }:
    daveShield {
      exec = wrappedOpenCode;
      extraPkgs = extraPkgs ++ openCodeExtraPkgs;
      extraCombinators = extraCombinators ++ openCodeExtraCombinators;
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
