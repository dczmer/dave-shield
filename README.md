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

## jailMe (jail.nix)

A wrapper over [jail.nix](https://github.com/MohrJonas/jail.nix) that bundles some common configuration and packages that you can use to quickly sandbox any agent application.

`jail.nix` is a `nix` wrapper for configuring sandboxed environments using `bubblewrap`. It's focused on preventing privilege escalation by blocking `setuid` programs and provides a high-level interface for configuring `linux namespaces` for isolation.

`jailMe` configuration:
- Uses a persistent `$HOME` directory `~/.local/share/jail.nix/home/dave-shield`.
- Sets a fake `hostname` (default `dave-shield`).
- Shares the host network by default.
- Mounts the current working directory (your project source directory for example).
- Installs a few useful command line tools, like `coreutils`, `curl`, etc.

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

### How to use it

```nix
let
  jail = jail-nix.lib.init pkgs;
  jailMe = import ./packages/jail-me.nix {
    inherit pkgs jail;
    };
in
{
  packages = {
    jailed-app = jailMe {
      name = "jailed-app";
      exec = pkgs.bash;
      # OPTIONAL: defaults to true
      hostNetwork = true;
      # OPTIONAL: additional packages available in the sandbox
      extraPkgs = with pkgs; [ ... ];
      # OPTIONAL: additional combinators config
      extraCombinators = with jail.combinators; [ ... ];
    };
  };
}
```

## Latest versions via `llm-agents`.

The [llm-agents.nix](https://github.com/numtide/llm-agents.nix) project adds packages for most popular agentic coding applications, updated daily.

I'm using this to make the jailed/sandboxed agents, but I've also added the un-sandboxed packages.

```bash
nix run .#opencode
nix run .#pi
```

## Jailed Agents

Agents wrapped with the `jailMe` function to provide a common system environment and persistent home directory. Each jailed agent has customized configuration to allow that agent to work inside of the restricted sandbox.

```bash
nix run .#jailedOpencode
nix run .#jailedPi
```

Install into your profile for easier use:

```bash
nix profile add .#jailedOpencode
opencode-jailed
```

```bash
nix profile add .#jailedPi
pi-jailed
```
## containers

Good isolation by running the agent on a container.

- File-system:
  * ephemeral FS
  * persistent /root volume for saving configuration
  * bind-mount your project root (and any other folders you need)
- Network:
  * able to access internet by default, no firewall or http filtering
  * or, use a host-only network and proxy requests to the internet and filter traffic
- PID/IPC/etc.:
  * all isolated
- `setuid` protection with `--runtime=runsc` (`gVisor`)
    
### pi-container

Build and load the container:
```bash
nix build .#piContainer
docker load < result
```

Launch it (I make a script and add it to my PATH):
```bash
# ensure persistent volume created
docker volume inspect davehome >/dev/null 2>&1 \
    || docker volume create davehome

docker run --rm  -e LOCAL_USER_ID="$(id -u)" \
    -v "$(pwd)":/source \
    -v davehome:/root \
    -v /home/dave/source/dave-shield/packages/pi/config:/root/.pi/agent \
    -it pi-coding-agent-container:latest
```

- Bind a persistent volume to `/root` to save any changes to the home directory.
- Bind the current working dir (project root) to `/source` on the container.
- Bind the required config and/or other shared directories needed for operation.
- I don't think the `LOCAL_USER_ID` part is required but try it if you have file permissions issues.

### opencode-container

Build and load the container:
```bash
nix build .#opencodeContainer
docker load < result
```

Launch it (I make a script and add it to my PATH):
```bash
# ensure persistent volume created
docker volume inspect davehome >/dev/null 2>&1 \
    || docker volume create davehome

docker run --rm  -e LOCAL_USER_ID="$(id -u)" \
    -v "$(pwd)":/source \
    -v davehome:/root \
    -v /home/dave/.config/opencode:/root/.config/opencode \
    -it opencode-container:latest
```

- Bind a persistent volume to `/root` to save any changes to the home directory.
- Bind the current working dir (project root) to `/source` on the container.
- Bind the required config and/or other shared directories needed for operation.

## docker sandboxes

TODO: docker has it's own sandbox and a new mcp gateway thing to investigate.

## dave-opensandbox

TODO: See what we can do with OpenSandbox.

## dave-proxy

TODO: network proxy to filter traffic. isolate container network and only allow traffic over white-list of domains and ips.

Example: https://sharats.me/posts/docker-with-proxy/

## dave-namespaces

TODO: Notes and scripts for working with namespaces; Script to manage an isolated network namespace we can use with the other sandboxes.

OS-level isolation. The system that docker manages to create isolated containers. You can use it directly (if you use Linux).

I already did a deep dive into managing namespaces. Merge notes into `docs`, create some helper packages/scripts, write about it here.

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

The easiest way to get full isolation and (possibly) kernel-level protection. Adds some overhead but can be mitigated with custom hypervisors like `firecracker-vim`. Row-hammer is still a thing, but you can't do much about that. Can also use a 'guest' kernel, like `gVisor`.

# chroot jails

The classic way to isolate a process from the rest of the file-system. Doesn't really give process/IPC/etc isolation though. It just prevents the application from accessing things outside of the jail directory. Might be useful still if applied along with namespaces and file-system isolation.

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

## docker/podman

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
