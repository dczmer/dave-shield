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
        jailed-agents = import ./packages/agent-jail.nix {
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
          # non-sandboxed apps from llm-agents, updated daily.
          claude-code-daily = {
            type = "app";
            program = "${llm-agents.packages.${system}.claude-code}/bin/claude";
          };
          claude-code-jailed = {
            type = "app";
            program = "${jailed-agents.packages.${system}.jailed-claude-code}/bin/claude";
          };
          opencode-daily = {
            type = "app";
            program = "${llm-agents.packages.${system}.opencode}/bin/opencode";
          };
          # TODO: opencode-jailed
        };
      }
    );
}
