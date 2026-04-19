# Overview

Research and implementation of isolated and sandboxing solutions and techniques for AI agents, and a tour of some of the underlying technologies that they use.

## Objective

- Agent is locked down to minimum access that it needs:
    * Process:
        + Shell commands run as unprivileged user, in a jail where it can only see the tools it's been given.
        + Should not be able to see or interact with other processes.
        + Should not be able to access `setuid` executables.
    * File-System:
        + R/W to project directory.
        + R/W to required directories (`~/.config/app/`, etc).
        + R/O directory binding support.
        + `tempfs` `tmp` directory.
        + Should not be able to see any packages/programs that I don't explicitly bind.
    * Network:
        + Segmentation from host network (and other sandboxes).
        + HTTP proxy with domain white-list.
    * MCP Servers:
        + Each server/tool needs it's own configuration and management as well.
    * Logging:
        + Audit logs to review access and violations.
        + Debug blocking of legitimate access.
    * Supply Chain:
      + Block package managers (`npm`, `pip`) from accessing the internet; use a privileged shell to install new packages.
      + Block all post-install scripts.

# Packages What I Made

## dave-shield (jail.nix)

[jail.nix on GitHub](https://github.com/MohrJonas/jail.nix)

`jail.nix` is a `nix` wrapper for configuring sandboxed environments using `bubblewrap`. It's focused on preventing privilege escalation by blocking `setuid` programs and provides a high-level interface for configuring `linux namespaces` for isolation.

Pros:
- Nicely sandboxed: PIDs, IPC, users, file-system.
- Network can be disabled (either _completely_ off, or use system network)
- Can _ONLY_ access the executables and packages provided by the `nix` derivation (call with `extraPkgs` to configure).
- Uses `bubblewrap`, a subset of Linux Namespaces that hardens against `setuid` privilege escalation.
- Can use a `seccomp` profile to block dangerous syscalls.
- Nix!

Cons:
- No custom network namespace or separate `iptables`.
- No HTTP proxy.
- No kernel protection, like `gVisor` (but could use with SELinux or AppArmor).
- No audit or alerts for violations.

I use it to make `devShells` or custom packages to run with `nix run`.

The `daveShell` library method builds wraps a program in a pre-configured sandbox environment. It has the following configuration:

- Uses a persistent `$HOME` directory `~/.local/share/jail.nix/home/dave-shield`.
- Sets `hostname` to `dave-shield`.
- Shares the host network by default.
- Mounts the current working directory (your project source directory for example).
- Installs a few useful command line tools, like `coreutils`, `curl`, etc.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    dave-shield.url = "github:dczmer/dave-shield";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      dave-shield,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        daveShield = dave-shield.lib.${system}.daveShield;
      in
      {
        packages = {
          jailedShell = daveShield { exec = pkgs.bash; };
        };
      }
    );
}
```

To add more packages to your environment, pass the `extraPkgs` option:

```nix
jailedshell = daveshield {
  exec = pkgs.bash;
  extrapkgs = with pkgs; [
    # additional packages
    uv
  ];
};
```

Customize the sandbox by with additional [combinators](https://alexdav.id/projects/jail-nix/combinators/):

```nix
jailedshell = daveshield {
  exec = pkgs.bash;
  extraCombinators = with dave-shield.lib.${system}.jailCombinators; [
    # additional combinators
    (rw-bind "/foo" "/bar")
    (wrap-entry (entry: ''
      echo 'Inside the jail!'
      ${entry}
      echo 'Cleaning up...'
    ''))
  ];
};
```

> NOTE: I exported `jail.combinators` from the version of `jail.nix` used in the `dave-shield` flake. Use the provided `lib.jailCombinators` instead of adding `jail.nix` as an input for your own flake, to make sure we don't have issues due to conflicting versions of dependencies.

Customize further by initializing a new sandbox configuration, instead of using the provided `daveShield`:

```nix
myShield = dave-shield.lib.${system}.jailMeLib.init {
  # will use hostname `myShield`.
  # will use persistent home dir `~/.local/share/jail.nix/home/myShield/`.
  name = "myShield";
  # will completely isolate from host network
  hostNetwork = false;
};
jailedShell = myShield { exec = pkgs.bash; };
```
## Jailed OpenCode

[Personal OpenCode config using daveShield](./packages/opencode/README.md).

## dave-opensandbox

TODO: See what we can do with OpenSandbox.

## dave-namespaces

TODO: Notes and scripts for working with namespaces; Script to manage an isolated network namespace we can use with the other sandboxes.

## dave-proxy

TODO: Squid proxy to filter HTTP traffic.

# General Suggestions

## Run agents as a restricted user

* Restricted user:
    + No `sudo` access
    + Member only to single-purpose group.
    + Never run `docker` (or anything) as root.

## Package Managers (NPM, etc)

+ Disable post-install scripts (`npm`)
+ Disable package install/update in the environment where the agent runs, have another way of running to manually install/update packages.

## Agent/MCP Configuration

* Ensure required security configuration is applied to the agent:
    + Claude has a sandbox mode, which can be configured to do much of this (but it kind of sucks).
    + Always lock down tool calls, MCP servers, and file-system permissions.
* Playwright MCP/CLI:
    + Allow `localhost` and specific port(s).
    + white-list of allowed domains.

## Network proxies and firewalls

- Use network segmentation and firewall.
- Network proxies with domain filtering, like `squid`.

## Docker security

- Run rootless.
- Managed network; segmentation.
- Don't mount sensitive files, Unix sockets (and never the Docker daemon socket).
- Keep the Docker runtime up to date.
- TODO (need more research):
  * `--security-opt=no-new-privileges`
  * dropping all privileges with `--cap-drop=all`, and only explicitly adding the capabilities you need using `--cap-add`
  * monitor logs regularly to look for issues and anomalies

# Off-the-Shelf Solutions

## Claude Code Sandbox Mode

Pros:
- Built-in.
- Isolated file-system.
- Integrated HTTP proxy.
- Sandbox settings apply to all processes launched by the agent.
- Works on Linux (`bubblewrap`), and also on Mac (`seatbelt`).

Cons:
- Claude can just choose to bypass it, unless you add extra configuration to prevent that.
- No kernel or `setuid` protection.
- Not isolated from the other applications and commands on the system.
- Can't really configure it. Or I don't care enough about Mac to learn about `seatbelt` low-level configuration.
- On Mac, you can't launch headless web browsers because they all depend on an IPC protocol that is blocked, and not configurable.

Overall better than nothing, especially on Mac, which doesn't have `cgroups`. Configure carefully.

But this sandbox wasn't designed as a jail. It was actually designed as a _convenience_ feature to reduce "prompt fatigue". In a restricted environment, you can feel a little more comfortable auto-accepting things and letting Claude run without supervision. So i don't consider this a complete solution, but it's worth using if you are on Mac.

The biggest issue I found is that the IPC isolation on the Mac sandbox prevents you from launching Chromium or FireFox via `playwright`. I'd like to be able to use those tools and just lock them down manually with allow-lists. But you can just tell Claude to try again and "bypass the sandbox" and it works :/

## OpenSandbox

TODO: This looks pretty comprehensive...

## Firejail

Sandbox solution for isolating and restricting applications using `namespaces`.

Use a pre-defined 'profile' for the app you want to run rather than requiring you to configure all of the options manually. Has generic, general purpose profiles with different isolation levels, and app-specific profiles that are more precise.

Also allows you to apply `seccomp` filters with your profile to block dangerous `syscalls`.

Can generate a `AppArmor` profile for you to use for kernel-level protection.

I didn't spend a lot of time on this because OpenSandbox sounded like a better solution. But the pre-configured profiles make it easy to run applications with complicated sandbox requirements, like Chromium or Firefox, or GUI applications, for example.

# Virtual Machines

TODO: The easiest way to get full isolation and (possibly) kernel-level protection. Adds some overhead but can be mitigated with custom hypervisors like `firecracker-vim`. Row-hammer is still a thing, but you can't do much about that. Can also use a 'guest' kernel, like `gVisor`.

# chroot jails

TODO: The classic way to isolate a process from the rest of the file-system. `chroot` inside of a sandbox, or is that a hat on a hat?

# namespaces and cgroups

## cgroups

TODO: Control resource-usage for groups of processes. I have extensive notes and examples, make a TLDR explanation and simple example here. You can use `systemd` to manage these and make them persistent.

## linux namespaces

TODO: Isolate your application from the rest of the system using a feature of the Linux kernel. I have extensive notes and examples, which probably require their own series of blogs to explain. Make a TLDR explanation and a simple example to illustrate the point.

## bubblewrap

TODO: Higher-level wrapper for configuring `cgroups` and `namespaces`. A wrapper for a _subset_ of user namespaces, focused on preventing privilege escalation. Docs say it doesn't support changing `iptables` on the network namespace.

## jail.nix

TODO: Even higher-level wrapper for `bubblewrap`, used to sandbox `nix` packages

# Containerization

## docker/etc

TODO: Exactly what kind of isolation does `docker` provide by default? What can be configured? Uses the same kernel, does not shield from kernel-level exploits. Container escapes? Exfiltration from mounted file-systems and socket files?
seccomp profiles.

## microvm and kata containers

TODO: Fast, lightweight container runtime.

## gvisor

TODO: Intercepts `syscalls` and acts as a guest kernel.

# AppArmor/SELinux

TODO: kernel-level restrictions, auditing, and logging with per-app profiles.

# seccomp

TODO: Use with AppArmor/SELinux: you may not be able to fully block a given `syscall` and have the app work, but you can put limits on use of that `syscall` with AppArmor.
