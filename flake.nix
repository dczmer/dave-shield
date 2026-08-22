{
  description = "Flake template";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    jail-nix.url = "sourcehut:~alexdavid/jail.nix";
    llm-agents.url = "github:numtide/llm-agents.nix";
  };
  outputs =
    {
      nixpkgs,
      flake-utils,
      jail-nix,
      llm-agents,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ llm-agents.overlays.shared-nixpkgs ];
        };
        # common packages for all sandboxes
        commonPkgs = import ./packages/commonPkgs.nix {
          inherit pkgs;
        };
        # jail-me library
        jail = jail-nix.lib.init pkgs;
        jailMe = import ./packages/jail-me.nix {
          inherit pkgs jail;
        };
        # agents
        jailedOpenCode = pkgs.callPackage ./packages/opencode {
          inherit jail jailMe;
        };
        jailedPi = pkgs.callPackage ./packages/pi {
          inherit jail jailMe;
        };
      in
      {
        lib = {
          # use jailMe.init "name" to create an env with a different name and home dir.
          jailMeLib = jailMe;
          # use the same combinators from the version this flake is using:
          jailCombinators = jail.combinators;
          # create a customized sandbox for opencode
          makeJailedOpenCode = jailedOpenCode.lib.makeJailedOpenCode commonPkgs;
          # create a customized sandbox for pi
          makeJailedPi = jailedPi.lib.makeJailedPi commonPkgs;
        };
        packages = {
          # example use of daveShield interface:
          jailedShell = jailMe {
            name = "jaied-shell";
            # executable to sand-box
            exec = pkgs.bash;
            # extra packages to make available
            extraPkgs = with pkgs; [
              nethack
              iputils
            ] ++ commonPkgs;
            # additional combinators to customize
            extraCombinators = with jail.combinators; [
              (wrap-entry (entry: ''
                echo 'Inside the jail!'
                ${entry}
                echo 'Cleaning up...'
              ''))
            ];
          };
          # OpenCode
          jailedOpenCode = jailedOpenCode.packages.jailedOpenCode;
          openCode = pkgs.llm-agents.opencode;
          # Pi
          jailedPi = jailedPi.packages.jailedPi;
          pi = pkgs.llm-agents.pi;
        };
        devShells = {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              uv
              nodejs
              prettierd
              jailedPi.packages.jailedPi
            ];
          };
        };
      }
    );
}
