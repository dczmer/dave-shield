{
  pkgs,
  jail,
  jailMe,
  ...
}:
let
  # pi with nodejs (which bundles npm and npx) on PATH, so pi can
  # install/run npm-based extensions and skills without a system-wide
  # node installation. Merging via symlinkJoin keeps pi's share/man etc.
  piWithNode = pkgs.symlinkJoin {
    name = "pi";
    paths = [ pkgs.llm-agents.pi ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/pi \
        --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.nodejs ]}
    '';
  };
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
  packages = {
    piWithNode = piWithNode;
  };
}
