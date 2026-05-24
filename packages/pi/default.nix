{
  llm-agents,
  jail,
  daveShield,
}:
let
  piExtraPkgs = [
    # this should make pi available in subshells so we can implement subagents
    llm-agents.pi
  ];
  piExtraCombinators = with jail.combinators; [
    (readwrite (noescape "~/.pi"))

    # NOTE: temporary while i'm working on this extensions package
    (readwrite (noescape "~/source/dave-shield"))
    (readwrite (noescape "~/source/dave-pi-extensions"))
  ];
  makeJailedPi =
    {
      extraPkgs ? [ ],
      extraDirs ? [ ],
      extraCombinators ? [ ],
    }:
    daveShield {
      exec = llm-agents.pi;
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
    unjailedPi = llm-agents.pi;
  };
}
