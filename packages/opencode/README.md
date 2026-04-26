# jailedOpenCode

This package creates a sandboxed opencode using jail.nix.

# Usage

```nix
{
  description = "Flake description";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    dave-shield.url = "github:dczmer/dave-shield";
  };
  outputs =
    {
      nixpkgs,
      flake-utils,
      dave-shield,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      in
      {
        packages = {
          jailedOpenCode = dave-shield.packages.${system}.jailedOpenCode;
        };
      };
    );
}
```

To add custom packages, allow access to additional directories, or use custom "combinators", use the `makeJailedOpenCode` function instead:

```nix
let
  pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
  makeJailedOpenCode = dave-shield.lib.${system}.makeJailedOpenCode;
in
{
  packages = {
    jailedOpenCode = makeJailedOpenCode {
      extraPkgs = [ pkgs.gh ];
      extraDirs = [ "~/source/skill-issues" ];
    };
  };
};
```

Example of using additional combinators directly:

```nix
let
  pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
    makeJailedOpenCode = dave-shield.lib.${system}.makeJailedOpenCode;
    jailCombinators = dave-shield.lib.${system}.jailCombinators;
in
{
  packages = {
    jailedOpenCode = makeJailedOpenCode {
      extraCombinators = with jailCombinators; [
          (readonly (noescape "~/mount/this/directory/readonly"))
      ];
    };
  };
};

```

# Configuration

> NOTE: This jailed application is allowed RW access to your `~/.config/opencode`, `~/.local/share/opencode`, and `~/.local/state/opencode` to allow them to use the exact same configuration and providers.

OpenCode will use your `~/.opencode` as initial configuration.
This package will merge and override those settings by using `$OPENCODE_CONFIG` environment variable.
In your project, you can define a `.opencode` at the document root to override that.

Suggested Configuration:

1. I keep `~/.config/opencode/opencode.json` minimal but set permissions like `"*": "ask"` so the default for any non-configured project use is to ask before any action.
2. The config bundled with this model will be used from inside of a sandboxed environment, so it opens up the permissions to allow the agent to do more without constantly prompting.
3. Then add a `.opencode/opencode.json` to your project root and override that to make adjustments.

# Skills

Skills (and agents, plugins, etc.) are a little hard to manage with a nix package.

OpenCode doesn't support bundling skills and agents together, so installing any skills with custom agents requires multiple steps to copy/symlink the directories to the correct place.

OpenCode provides a `OPENCODE_CONFIG_DIR` environment variable that lets us specify a configuration folder that works just like a `.opencode` directory. It includes the configuration files, but also the `agents` and `skills` issues that we'd want to use to link-in our skill packages from the nix store.

However, the nix store is read-only and opencode needs to install `node_modules` with bun at startup. This causes OpenCode to crash at startup :(

Instead, skills, agents, and other plugins need to be managed imperatively and installed manually by the user. For example, you might checkout a git repository of skills or plugins and then copy or symlink the required folders into `~/.opencode` to install them.

But if you use a symlink, then the sandboxed environment needs to be able to access the target folder of that symlink (the repository directory).

```
# add the link target of ~/.config/opencode/skills/skill-issues to the sandbox
# so we can access the files.
makeJailedOpenCode { extraDirs = [ "~/source/skill-issues" ]
```

## Alternative: flake input + `try-ro-bind` to install skill folders

```nix
skill-issues-src = {
  url = "github:dczmer/skill-issues";
  flake = false;
};
```

```nix
# build the skill-issues derivation
skillIssues = stdenv.mkDerivation {
  name = "skill-issues";
  version = "0.1";
  src = skill-issues-src;
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  installPhase = ''
    mkdir -p $out
    cp -r ./agents ./skills $out
  '';
};

# bind skill-issues agents and skill files
(try-ro-bind "${skillIssues}" (noescape "~/.config/opencode/skills/skill-issues"))
(try-ro-bind "${skillIssues}/agents" (noescape "~/.config/opencode/agents/skill-issues"))
```

# RTK

`rtk` is included as a default package but you have to configure it yourself.

```
nix-shell -p rtk

rtk -g --opencode
```

If `rtk` is not installed, it will show a warning message at startup and then it won't try to use it again.

# Global AGENTS.md

The included `AGENTS.md` will be bind-mounted "read-only" to `~/.config/opencode/AGENTS.md` inside of the sandbox environment, which means it will overwrite any existing file.

# Lessons and Observations

1. OpenCode custom agents are pretty cool, especially with 'primary' agents. Provides much more than a Claude agent.
2. OpenCode installs things with `bun` into your `~/.config` directory when it starts up, which makes it difficult to package and manage a config directory with `nix` :(
3. OpenCode constantly prunes your context window. This helps keep your context usage lower but completely invalidates the benefit of kv caching that can actually cause excess token-burn.
4. OpenCode doesn't make it easy 'bundle' collections of subagents and skills as a single unit. You have to make a symlink for each folder individually.
5. You can use `jail.nix` to bind-mount files into `~/.config/opencode` in order to manage config, AGENTS.md, custom subagents and skills. This effectively gets around the other issues but is more complicated.

# Support for Playwright and Chromium in the sandbox

To run any node-installed programs, you need to `ro-bind /usr/bin/env` for the she-bangs.

You will need to install the playwright browsers as a separate package and set env vars to point to the right location:

https://wiki.nixos.org/wiki/Playwright#Installing_browsers_for_Playwright_under_NixOS

Example of running Chromium from inside of a sandbox: https://wiki.archlinux.org/title/Bubblewrap/Examples#Chromium

I would try doing the minimal amount of rw binding possible. you don't have to bind anything under `$HOME`, because we're running Bubblewrap with a persistent home.

# Support for `uv` in the sandbox

# TODO

- some way to manage uv/node so the agent can't install packages but i can
- some kind of network proxy/filter to block or monitor outgoing web requests
- opencode-mem: https://github.com/tickernelz/opencode-mem
