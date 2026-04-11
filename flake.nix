{
  description = "Flake template";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    jail-nix.url = "sourcehut:~alexdavid/jail.nix";
  };
  outputs =
    {
      nixpkgs,
      flake-utils,
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
        jailMeLib = import ./packages/jail-me.nix {
          inherit pkgs jail;
        };
        daveShield = jailMeLib.init {
          name = "dave-shield";
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
        };
      }
    );
}
