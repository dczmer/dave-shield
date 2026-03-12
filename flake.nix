{
  description = "Flake template";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    llm-agents.url = "github:numtide/llm-agents.nix";
    jail-nix.url = "sourcehut:~alexdavid/jail.nix";
  };
  outputs =
    {
      nixpkgs,
      flake-utils,
      llm-agents,
      jail-nix,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        jail = jail-nix.lib.init pkgs;
        claude-code-pkg = llm-agents.packages.${system}.claude-code;
        opencode-pkg = llm-agents.packages.${system}.opencode;
        jailOptions = with jail.combinators; [
          network
          time-zone
          no-new-session
          # allow acces to ONLY the project i'm working on.
          # we'll add more directory access per-agent, to manage it's own state and config later
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
        devShells = {
          default = pkgs.mkShell {
            packages = [
              (makeJailedClaudeCode { })
            ];
            shellHook = '''';
          };
        };
      }
    );
}
