# jail.nx and bubblewrap

## jail.nix

[agent-jail.nix](./packages/agent-jail.nix)

High-level nix wrapper for [bubblewrap](https://github.com/containers/bubblewrap)

Combined with nix, this is like full docker-ization, without the overhead of docker, or the layer of indirection when interacting with the container environment.

This was easy to setup and configure for file-system and execution environment isolation. However, I think we need an additional solution for managing a network firewall.

## bubblewrap

[bubblewrap](https://github.com/containers/bubblewrap)

a tool for constructing sandboxes, not a ready-made sandbox with a specific security policy. that means, it's on you to do it right.

a big selling point here is that bubblewrap is designed to be more resilient to priv escalation than tools like `systemd-nspawn` or even `docker`, and without the overhead of full virtualization.

however, the quality of isolation and security depends entirely on how bubblewrap options are configured.

can use it directly with `bwrap`, but we'll be using jail.nix for now.

- user namespaces:
    * project to allow unprivileged users to access container features, but there are still many concerns over it's safety
    * bubblewrap implements a setuid implementation of a subset of user namespaces:
        + NOTE: it says it "does not allow control over iptalbles". does that mean i can't firewall my app? that doesn't seem right...
    * maintainers believe it provides full priv escalation security. sets `PR_SET_NO_NEW_PRIVS` to turn off setuid binaries, the traditional way to get out of chroots.
    * hides all but current uid and gid from the sandbox
- ipc namespaces:
    * sandbox gets its own copy of all IPC and shared memory
- pid namespaces:
    * will not see processes outside of the sandbox
- network namespaces:
    * will not see network devices
    * will see it's own network with only lo
- uts namespaces:
    * sandbox will have it's own hostname
- seccomp filters:
    * can pass in compiled seccomp filters to limit which syscalls can be performed in the sandbox
- [limitations](https://github.com/containers/bubblewrap?tab=readme-ov-file#limitations)
- https://akmatori.com/blog/bubblewrap-sandboxing-guide


What bubblewrap protects against:
- Filesystem access outside bind mounts
- Process visibility (with PID namespace)
- Network access (with network namespace)
- IPC between sandboxed and host processes

What bubblewrap does NOT protect against:
- Kernel exploits (sandbox shares the kernel)
- Side-channel attacks
- Data exfiltration through allowed network access
- Covert channels through shared resources

For higher security requirements, combine bubblewrap with:
- Seccomp filters to restrict syscalls
- SELinux/AppArmor policies
- Resource limits via cgroups
- Network filtering with iptables/nftables

## apparmor

Mandator access control solution as a linux kernel module that can restrict a program's capabilities with per-program configuration.

https://techbuzzonline.com/linux-security-hardening-apparmor-guide/

- Network access
- Raw socket access
- File-system
- Execution
- Includes a 'learning' mode to log, but not block, violations
- Alternative to SELinux, which critics say is difficult to configure (it is)
- SELinux is more granular and complex (but i do know how to debug it)

## cgroups resource limits

- organize processes into hierarchical groups, called `cgroups`
- systemd uses cgroups to manage all service units
- resource limiting:
    * cpu time
    * memory
    * network bandwith
- of interest:
    * `blkio` limit i/o and block devices
    * `devices`
    * `memory`
    * `net_cls` tags network traffic so it can be identified as belonging to this cgroup
    * `net_filter` firewall controlled with `iptables`
    * `pids` sets limitations for multiple processes and children in a cgroup
- the cgroup gets all of the namespaced resources mentioned in the bubblewrap section

## seccomp

TODO: https://medium.com/@mughal.asim/understanding-seccomp-and-how-it-compares-to-apparmor-for-container-security-5317b3e9b1d6

## network filtering

one option is bubblewrap with `unshare-net` so we only have an isolated loopback, then using a local http proxy with filtering to provide network access.

another option is to not `share-net` and use the network namespaces with iptables to implement a firewall.
