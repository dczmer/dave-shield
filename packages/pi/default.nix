{
  pkgs,
  jail,
  jailMe,
  ...
}:
let
  piExtraPkgs = [
    # so it can invoke headless sessions directly
    pkgs.llm-agents.pi
  ];
  piExtraCombinators = with jail.combinators; [
    (readwrite (noescape "~/.pi"))
  ];
  makeJailedPi =
    {
      extraPkgs ? [ ],
      extraDirs ? [ ],
      extraCombinators ? [ ],
    }:
    jailMe {
      name = "pi-jailed";
      exec = pkgs.llm-agents.pi;
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
}
