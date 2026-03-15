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

## Docker security

# Off-the-Shelf Solutions

## Claude Code Sandbox Mode

## OpenSandbox

## Firejail

# Virtual Machines

# chroot jails

# cgroups

## bubblewrap

## jail.nix

# Containerization

## docker/etc

## microvm and kata containers

# gvisor

# seccomp

# falco

# OpenSnitch

# AppArmor/SELinux
