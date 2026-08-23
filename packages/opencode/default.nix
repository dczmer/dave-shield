{
  pkgs,
  jail,
  jailMe,
  ...
}:
let
  openCodeExtraPkgs = [
    # so it can invoke headless sessions directly
    pkgs.llm-agents.opencode
  ];
  openCodeExtraCombinators = with jail.combinators; [
    # share the opencode config from my home dir.
    # otherwise, you have to configure and auth in each new sandbox environment.
    (readwrite (noescape "~/.config/opencode"))
    (readwrite (noescape "~/.local/share/opencode"))
    (readwrite (noescape "~/.local/state/opencode"))
  ];
  makeJailedOpencode =
    {
      extraPkgs ? [ ],
      extraDirs ? [ ],
      extraCombinators ? [ ],
    }:
    jailMe {
      name = "opencode-jailed";
      exec = pkgs.llm-agents.opencode;
      extraPkgs = extraPkgs ++ openCodeExtraPkgs;
      extraCombinators =
        extraCombinators
        ++ openCodeExtraCombinators
        ++ (map (d: jail.combinators.readwrite (jail.combinators.noescape d)) extraDirs);
    };
in
{
  lib = {
    makeJailedOpencode = makeJailedOpencode;
  };
}
