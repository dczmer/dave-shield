# Overview

Research and implementation of isolated and sandboxing solutions and techniques for AI agents, and a tour of some of the underlying technologies that they use.

## Objective

My initial objective was to create a sandboxed environment to run AI agents. The agent should be locked in a jail and only allowed to interact with the system and network in a tightly managed way, using a white-list only approach to resources like network and file-system. It should be isolated from other processes and `setuid` binaries. It should also keep audit logs that can be reviewed for unexpected access, or to tell me which resources need to white-list when legitimate access is blocked.

- Agent is locked down to minimum access that it needs:
    * Process:
        + Shell commands run as unprivileged user, in a jail where it can only see the tools it's been given
        + Should not be able to see or interact with other processes
        + Should not be able to access `setuid` executables
    * File-System:
        + R/W to project dir.
        + R/W to agent's manged dirs (config, state, etc).
        + R/O binding support.
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

In fact, I'd like to keep it jailed in a way that it can't even see this flake or any of the scripts or files used to configure it's environment.

# General Suggestions

## Run as restricted user

* Restricted user:
    + no sudo access
    + never run docker (or anything) as root

## Package Managers (NPM, etc)

* NPM:
    + disable post-install scripts
    + disable all network access in the environment where the agent runs, have another way of running as a privileged user to install/update packages.

## Agent/MCP Configuration

* Ensure required security configs are applied to agent:
    + Claude has a sandbox mode, which can be configured to do much of this
    + always lock down tool, mcp server, and filesystem permissions
* Playwright MCP/CLI:
    + allow localhost and specific port(s)
    + white-list of allowed domains

## Network proxies and firewalls

- local squid proxy in intercept mode
- lan/intranet proxy

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

pretty good option, especially on mac which doesn't have cgroups. configure carefully. uses cgroups and namespaces on linux, 'seatbelt' on mac. covers fs isolation, network filtering, process isolation, and logging and it's already built-in.

[Claude Code Sandbox Mode](./docs/claude-code-sandbox-mode.md)

## OpenSandbox

## Firejail

# Virtual Machines

# chroot jails

# namespaces and cgroups

[Namespaces and cgroups](./docs/namespaces-and-cgroups.md)

## bubblewrap

higher-level wrapper for configuring cgroups and namespaces.

## jail.nix

even higher-level wrapper for bubblewrap, used to sandbox nix packages

# Containerization

## docker/etc

TODO: what kind of isolation does docker provide by default; what can be configured?
uses the same kernel, does not shield from kernel-level exploits.
container escapes.
exfiltration from mounted filesystems.
seccomp profiles.

## microvm and kata containers

# gvisor

# seccomp

# falco

# OpenSnitch

# AppArmor/SELinux


# Idea for mega-sandbox experiment:

- unpriv user (in user namespace)
- neuter npm
- lock down agent config
- lock down playwright config
- holistic net proxy: network namespace (iptables) => squid netns (domains) => system
- custom cgroup with resource limits and namespace isolation:
    * using bwrap or jail.nix
    * launch with custom chroot
- use a seccomp profile to block dangerous syscalls
- use gvisor to emulate kernel and block dangerous syscalls
- use falco to monitor for dangerous effects
- configure apparmor or selinux on the host system
