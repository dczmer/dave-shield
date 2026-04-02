{
  pkgs,
  system,
  llm-agents,
  jail-nix,
  ...
}:
let
  jail = jail-nix.lib.init pkgs;
  opencode-pkg = llm-agents.packages.${system}.opencode;
  jailOptions = with jail.combinators; [
    network
    time-zone
    no-new-session
    mount-cwd
  ];
  commonPkgs = with pkgs; [
    bashInteractive
    curl
    wget
    jq
    git
    which
    ripgrep
    gnugrep
    gawkInteractive
    ps
    findutils
    gzip
    unzip
    gnutar
    diffutils
    coreutils
  ];
  jailCombinators =
    extraPkgs:
    with jail.combinators;
    (
      jailOptions
      ++ [
        (readwrite (noescape "~/.config/opencode"))
        (readwrite (noescape "~/.local/share/opencode"))
        (readwrite (noescape "~/.local/state/opencode"))

        # add these pkgs bin/ directories to $path
        (add-pkg-deps commonPkgs)
        (add-pkg-deps extraPkgs)
      ]
    );
  makeJailedOpenCode =
    {
      extraPkgs ? [ ],
    }:
    jail "jailed-opencode" opencode-pkg (jailCombinators extraPkgs);
  makeJailedShell =
    {
      extraPkgs ? [ ],
    }:
    jail "jailed-shell" pkgs.bash (jailCombinators extraPkgs);
in
{
  lib = {
    inherit makeJailedOpenCode makeJailedShell;
  };
  packages = {
    jailed-opencode = (makeJailedOpenCode { });
    jailed-shell = (makeJailedShell { });
  };
}
