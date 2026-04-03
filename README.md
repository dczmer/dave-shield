# Overview

Research and implementation of isolated and sandboxing solutions and techniques for AI agents, and a tour of some of the underlying technologies that they use.

## Objective

- Agent is locked down to minimum access that it needs:
    * Process:
        + Shell commands run as unprivileged user, in a jail where it can only see the tools it's been given
        + Should not be able to see or interact with other processes
        + Should not be able to access `setuid` executables
    * File-System:
        + R/W to project dir.
        + R/W to agent's manged dirs (config, state, etc).
        + R/O binding support.
        + `tempfs` tmp dir.
        + Should not be able to see anything I don't explicitly bind.
    * Network:
        + Localhost (socket files are still dangerous, as are other exposed localhost services)
        + white-list of domains I manage, everything else is blocked and logged.
        + Only http/https (or protocols I white-list and manage)
    * MCP Servers:
        + white-list only
        + Each server/tool needs it's own configuration and management as well
    * Logging:
        + Audit logs to review access and violations
        + Debug blocking of legitimate access

# Packages What I Made

## agent-jail (opencode + jail.nix)

I'm using this to run opencode with relaxed permissions configuration, to allow agents to run without having to constantly babysit prompts.

Pros:
- Nicely sandboxed: PIDs, IPC, users, filesystem.
- Network can be disabled (either _completely_ off, or use system network)
- Can _ONLY_ access the executables and packages provided by the nix derivation (call with `extraPkgs` to configure).
- Uses `bubblewrap`, a subset of Linux Namespaces that hardens against `setuid` privilege escalation.
- Nix!

Cons:
- No custom network namespace or iptables
- No HTTP proxy
- No kernel protection, like gVisor (but could use with SELinux or AppArmor)
- No audit or alerts for violations

I use it in a devShell like this:

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
        pkgs = nixpkgs.legacyPackages.${system};
        myPackages = with pkgs; [
            git
            uv
            playwright
        ];
        jailedOpenCode = dave-shield.lib.${system}.makeJailedOpenCode {
          extraPkgs = myPackages;
        };
        # use the shell to explore and test the sand-boxed environment
        jailedShell = dave-shield.lib.${system}.makeJailedShell {
          extraPkgs = myPackages;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs =
            with pkgs;
            [
              jailedOpenCode
              jailedShell
            ];
        };
      }
    );
}
```

# General Suggestions

## Run as restricted user

* Restricted user:
    + no sudo access
    + member of only to single-purpose group
    + never run docker (or anything) as root

## Package Managers (NPM, etc)

+ disable post-install scripts (NPM)
+ disable network/registry access in the environment where the agent runs, have another way of running to manually install/update packages.

## Agent/MCP Configuration

* Ensure required security configs are applied to agent:
    + Claude has a sandbox mode, which can be configured to do much of this
    + always lock down tool, mcp server, and filesystem permissions
* Playwright MCP/CLI:
    + allow localhost and specific port(s)
    + white-list of allowed domains

## Network proxies and firewalls

- network proxies with domain filtering, like squid
- use network segmentation and firewall

## Docker security

- run rootless
- managed network; segmentation
- don't mount sensitive files, unix sockets (and never the docker daemon socket)
- latest updates
- `--security-opt=no-new-privileges`
- dropping all privileges with `--cap-drop=all`, and only explicitly adding the capabilities you need using `--cap-add`
- monitor logs regularly to look for issues and anomalies

# Off-the-Shelf Solutions

## Claude Code Sandbox Mode

Pros:
- Built-in.
- Isolated filesystem.
- HTTP proxy.
- Sandbox settings apply to all processes launched by the agent.
- Works on Linux (`bubblewrap`), and also on Mac (`seatbelt`).

Cons:
- Claude can just choose to bypass, unless you add extra configuration to prevent that.
- No kernel or `setuid` protection.
- Not isolated from the other applications and commands on the system.
- Can't really configure it. Or I don't care enough about Mac to learn about `seatbelt`.
- On Mac, you can't launch headless web browsers because they all depend on an IPC protocol that is blocked, and not configurable.

pretty good option, especially on mac which doesn't have cgroups. configure carefully. uses cgroups and namespaces on linux, 'seatbelt' on mac. covers fs isolation, network filtering, process isolation, and logging and it's already built-in.

but this sandbox wasn't designed as a jail, it was actually designed as a _convenience_ feature to reduce "prompt fatigue". In a restricted environment, you can feel a little more comfortable auto-accepting things and letting Claude run without supervision. so i don't consider this a complete solution, but it's worth using if you are on Mac.

The biggest issue I found is that the IPC isolation on the Mac sandbox prevents you from launching chromium or firefox via playwright. I'd like to be able to use those tools and just lock them down manually with allow-lists.

## OpenSandbox

## Firejail

Sandbox solution for isolating and restricting applications using namespaces. Use a pre-defined 'profile' for the app you want to run rather than setting options manually. Has generic, general purpose profiles with different isolation levels, and app-specific profiles that are more precise.

Also allows you to apply `seccomp` filters with your profile to block dangerous syscalls.

Can generate a `AppArmor` profile for you to use for kernel-level protection.

# Virtual Machines

# chroot jails

# namespaces and cgroups

## cgroups

## linux namespaces

## bubblewrap

higher-level wrapper for configuring cgroups and namespaces.
a wrapper for a _subset_ of user namespaces, focused on preventing privilege escalation.
docs say it doesn't support changing iptables on the network namespace.

## jail.nix

even higher-level wrapper for bubblewrap, used to sandbox nix packages

# Containerization

## docker/etc

TODO: exactly what kind of isolation does docker provide by default? what can be configured?
uses the same kernel, does not shield from kernel-level exploits.
container escapes.
exfiltration from mounted filesystems.
seccomp profiles.

## microvm and kata containers

fast, lightweight container runtime.

# gvisor

intercepts syscalls and acts as a guest kernel.

# seccomp

use with apparmor/selinux: you may not be able to fully block a given syscall and have the app work, but you can put limits on use of that syscall with apparmor.

# AppArmor/SELinux
