{
  pkgs,
  system,
  llm-agents,
  jail-nix,
  ...
}:
let
  jail = jail-nix.lib.init pkgs;
  claude-code-pkg = llm-agents.packages.${system}.claude-code;
  #opencode-pkg = llm-agents.packages.${system}.opencode;
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
  makeJailedClaudeCode =
    {
      extraPkgs ? [ ],
    }:
    # https://alexdav.id/projects/jail-nix/combinators/
    jail "jailed-claude-code" claude-code-pkg (
      with jail.combinators;
      (
        jailOptions
        ++ [
          (readwrite (noescape "~/.config/opencode"))
          (readwrite (noescape "~/.local/share/opencode"))
          (readwrite (noescape "~/.local/state/opencode"))

          # add these pkgs bin/ directories to $PATH
          (add-pkg-deps commonPkgs)
          (add-pkg-deps extraPkgs)
        ]
      )
    );
in
{
  lib = {
    inherit makeJailedClaudeCode;
  };
  packages = {
    jailed-claude-code = (makeJailedClaudeCode { });
    #jailed-opencode = (makeJailedOpencode { });
  };
  apps = {
  };
  devShells = {
    default = pkgs.mkShell {
      packages = [
        (makeJailedClaudeCode { })
      ];
    };
  };
}
