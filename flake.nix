{
  description = "Experiments in packaging and sandboxing coding agents.";
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
        jailedOpencode = pkgs.callPackage ./packages/opencode {
          inherit jail jailMe;
        };
        jailedPi = pkgs.callPackage ./packages/pi {
          inherit jail jailMe;
        };
        # containers
        piContainer = import ./packages/pi/pi-container.nix {
          inherit pkgs commonPkgs;
        };
        opencodeContainer = import ./packages/opencode/opencode-container.nix {
          inherit pkgs commonPkgs;
        };
      in
      rec {
        lib = {
          # use jailMe.init "name" to create an env with a different name and home dir.
          jailMeLib = jailMe;
          # use the same combinators from the version this flake is using:
          jailCombinators = jail.combinators;
          # create a customized sandbox for opencode
          makeJailedOpencode = jailedOpencode.lib.makeJailedOpencode;
          # create a customized sandbox for pi
          makeJailedPi = jailedPi.lib.makeJailedPi;
        };
        packages = {
          # example use of daveShield interface:
          jailedShell = jailMe {
            name = "jaied-shell";
            # executable to sand-box
            exec = pkgs.bash;
            # extra packages to make available
            extraPkgs =
              with pkgs;
              [
                nethack
                iputils
              ]
              ++ commonPkgs;
            # additional combinators to customize
            extraCombinators = with jail.combinators; [
              (wrap-entry (entry: ''
                echo 'Inside the jail!'
                ${entry}
                echo 'Cleaning up...'
              ''))
            ];
          };

          #
          ######################################################################
          # Opencode
          ######################################################################
          #
          opencode = jailedOpencode.packages.unjailedOpencode;
          jailedOpencode = lib.makeJailedOpencode { extraPkgs = commonPkgs; };
          # To build the container:
          # ```
          # nix build .#opencodeContainer
          # docker load < result
          # ```
          #
          # Then run it (and add your own network/binds/etc):
          # ```
          # docker run -v "$(pwd):/source" -it opencode-container
          # ```
          opencodeContainer = opencodeContainer;
          ######################################################################
          ######################################################################
          #
          ######################################################################
          # Pi
          ######################################################################
          #
          # pi with nodejs/npm available on PATH (for npm-based extensions/skills)
          pi = jailedPi.packages.piWithNode;
          jailedPi = lib.makeJailedPi { extraPkgs = commonPkgs; };
          # To build the container:
          # ```
          # nix build .#piContainer
          # docker load < result
          # ```
          #
          # Then run it (and add your own network/binds/etc):
          # ```
          # docker run -v "$(pwd):/source" -it pi-coding-agent-container
          # ```
          piContainer = piContainer;
          ######################################################################
          ######################################################################
        };
        devShells = {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              uv
              nodejs
              prettierd
              packages.jailedPi
            ];
          };
        };
      }
    );
}
