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
        jailed-agents = import ./packages/agent-jail {
          inherit
            pkgs
            system
            llm-agents
            jail-nix
            ;
        };
      in
      {
        apps = {
          opencode-daily = {
            type = "app";
            program = "${llm-agents.packages.opencode}/bin/opencode";
          };
          jailed-opencode-daily = {
            type = "app";
            program = "${jailed-agents.packages.jailed-opencode}/bin/jailed-opencode";
          };
          jailed-shell = {
            type = "app";
            program = "${jailed-agents.packages.jailed-shell}/bin/jailed-shell";
          };
        };
      }
    );
}
