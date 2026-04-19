# AGENTS.md — dave-shield

## What this repo is

Nix flake providing sandboxed environments for AI agents using `bubblewrap` (via `jail.nix`). No tests, no CI, no linter.

## Commands

```sh
nix build                       # build all packages
nix build .#jailedOpenCode      # build single package
nix run .#jailedOpenCode        # run sandboxed opencode
nix develop                     # enter dev shell (or rely on direnv)
```

No `check`, `test`, `lint`, or `fmt` targets exist.

## Architecture

```
flake.nix                          # entry point, wires everything together
packages/jail-me.nix               # wraps jail.nix library: init → daveShield fn
packages/opencode/default.nix      # wraps opencode with sandbox config + combinators
packages/opencode/config/          # configs bind-mounted into the sandbox at runtime
```

- `jail.nix` (SourceHut input) provides `jail` lib and `jail.combinators`.
- `jail-me.nix` initializes with name/hostNetwork, returns a function `(exec, extraPkgs, extraCombinators) → sandboxed derivation`.
- `daveShield = jailMeLib.init { name = "dave-shield"; }` — the default sandbox.
- `makeJailedOpenCode` builds on `daveShield`, adds opencode-specific pkgs (rtk) and RW binds for `~/.config/opencode`, `~/.local/share/opencode`, `~/.local/state/opencode`.

## Key constraints

- `packages/opencode/config/AGENTS.md` is **not** a repo instruction file — it's bind-mounted read-only into `~/.config/opencode/AGENTS.md` inside the sandbox. Changing it affects sandbox behavior, not dev workflow.
- `llm-agents` overlay provides the `opencode` package. Override requires changing `flake.nix` inputs.
- Persistent home dir for sandboxed apps lives at `~/.local/share/jail.nix/home/dave-shield/`.
- `nixpkgs.config.allowUnfree = true` is set — needed for opencode package.
- Skills/agents/plugins must be installed imperatively (nix store is read-only, opencode needs to write `node_modules` at startup). See `packages/opencode/README.md`.

## Style

Nix files use `nixfmt` formatting. No formatter CI hook — run manually if editing `.nix`.

## Gotchas

- `mount-cwd` combinator must come after `persist-home` or they conflict (see `jail-me.nix:56`).
- `makeJailedOpenCode`'s `extraDirs` are RW-bound; for RO, pass `extraCombinators` with `(readonly ...)` directly.
