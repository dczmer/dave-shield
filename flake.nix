{
  description = "Flake template";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    jail-nix.url = "sourcehut:~alexdavid/jail.nix";
    llm-agents.url = "github:numtide/llm-agents.nix";
    skill-issues-src = {
      url = "github:dczmer/skill-issues";
      flake = false;
    };
  };
  outputs =
    {
      nixpkgs,
      flake-utils,
      jail-nix,
      llm-agents,
      skill-issues-src,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ llm-agents.overlays.default ];
        };
        # jail-me library
        jail = jail-nix.lib.init pkgs;
        jailMeLib = import ./packages/jail-me.nix {
          inherit pkgs jail;
        };
        daveShield = jailMeLib.init {
          name = "dave-shield";
        };
        # agents
        jailedOpenCode = pkgs.callPackage ./packages/opencode {
          inherit jail daveShield skill-issues-src;
        };
      in
      {
        lib = {
          # use daveShield for shared persistent home dir across applications.
          daveShield = daveShield;
          # use jailMe.init "name" to create an env with a different name and home dir.
          jailMeLib = jailMeLib;
          # use the same combinators from the version this flake is using:
          jailCombinators = jail.combinators;
          # create a customized sandbox for opencode
          makeJailedOpenCode = jailedOpenCode.lib.makeJailedOpenCode;
        };
        packages = {
          # example use of daveShield interface:
          jailedShell = daveShield {
            # executable to sand-box
            exec = pkgs.bash;
            # extra packages to make available
            extraPkgs = with pkgs; [
              nethack
              iputils
            ];
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
          unjailedOpenCode = jailedOpenCode.packages.unjailedOpenCode;
          # Pi
          pi = pkgs.llm-agents.pi;
        };
        devShells = {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              uv
              nodejs
              prettierd
              pkgs.llm-agents.pi
              rtk
            ];
          };
        };
      }
    );
}
