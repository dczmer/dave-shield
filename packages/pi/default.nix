{
  llm-agents,
  jail,
  daveShield,
  stdenv,
  symlinkJoin,
  makeWrapper,
}:
let
  configDir = stdenv.mkDerivation {
    name = "Jailed Pi Config";
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
  piExtraPkgs = [];
  piExtraCombinators = with jail.combinators; [
    (readwrite (noescape "~/.pi"))
  ];
  wrappedPi = symlinkJoin {
    name = "pi";
    paths = [
      llm-agents.pi
      configDir
    ];
    buildInputs = [ makeWrapper ];

    # TODO: this doesn't work. manage the configs in a separate repo w/ symlinks and we can remove these symlink joins from both packages.

    postBuild = ''
      wrapProgram $out/bin/pi
    '';
    meta = {
      mainProgram = "pi";
    };
  };
  makeJailedPi =
    {
      extraPkgs ? [ ],
      extraDirs ? [ ],
      extraCombinators ? [ ],
    }:
    daveShield {
      exec = wrappedPi;
      extraPkgs = extraPkgs ++ piExtraPkgs;
      extraCombinators =
        extraCombinators
        ++ piExtraCombinators
        ++ (map (d: jail.combinators.readwrite (jail.combinators.noescape d)) extraDirs);
    };
in
{
  lib = {
    makeJailedPi = makeJailedPi;
  };
  packages = {
    jailedPi = makeJailedPi { };
    unjailedPi = wrappedPi;
  };
}
