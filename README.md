# Overview

Research and implementation of isolated and sandboxing techniques for AI agents.

This is a nix flake with several modules implementing various solutions and ideas for sandboxing agents and devShells.

## Objective

The agent should be locked in a jail and only allowed to interact with the system and network in a tightly managed way, using a white-list only approach to resources like network and filesystem. It should be isolated from other processes and setuid binaries. It should also keep audit logs that can be reviewed for unexpected access, or to tell me which resources need to white-list when legitimate access is blocked.

- Agent is locked down to minimum access that it needs:
    * Process:
        + Shell commands as unpriv user, in a jail where it can only see the tools it's been given
        + Should not be able to see or interact with other processes
        + Should not be able to access suid executables
    * Filesystem:
        + R/W to project dir
        + R/W to agent's manged dirs (config, state, etc)
    * Network:
        + localhost
        + white-list of domains i manage
        + only http/https
    * MCP Servers:
        + white-list only
        + each server needs it's own management as well
    * Logging:
        + Audit logs to review access and violations
        + Debug blocking of legitimate access

In fact, I'd like to keep it jailed in a way that it can't even see this flake or any of the scripts or files used to configure it's environment.

## Solutions

- Always do these, even with other sandboxing solutions:
    * Restricted user:
        + no sudo access
        + never run docker (or anything) as root
    * NPM:
        + disable post-install scripts
        + disable all network access in the environment where the agent runs, have another way of running as a privileged user to install/update packages.
    * Playwright MCP/CLI:
        + allow localhost and specific port(s)
        + white-list of allowed domains
    * Ensure required security configs are applied to agent:
        + Claude has a sandbox mode, which can be configured to do much of this
        + always lock down tool, mcp server, and filesystem permissions

- Isolation and sandboxing:
    * Virtual Machines
    * Nix packages and devshells:
        + [jail.nix / seatbelt/bubblewrap](./docs/jail-nix.md)
    * Docker:
        + microcontainers
        + gVisor
        + falco
        + running with python and collecting logs
    * Microvm
    * Kata Containers
    * AppArmor
    * SELinux
    * Compsec
    * Local network proxy

# Inspiration

https://dev.to/andersonjoseph/how-i-run-llm-agents-in-a-secure-nix-sandbox-1899
https://alexdav.id/projects/jail-nix/
https://fast.io/resources/ai-agent-sandbox-environment/
for work/claude: https://code.claude.com/docs/en/sandboxing
https://open-sandbox.ai/


# gVisor


# claude sandbox mode

- `/sandbox`, chose "Sandbox BashTool, with regular permissions"
- configure `sandbox` options in settings.json:
    * sandbox settings in multipe config scopes will be merged
    * however, when a command fails due to sandbox restrictions, claude is prompted to analyze the issue and try again with `dangerouslyDisableSandbox`... why?:
        + these commands will still go through the normal claude prompting system (but even that seems to have a mind of it's own)
        + disable this with `"allowUnsandboxedCommands": false` in sandbox settings
    * `filesystem`:
        + white-list additional directories to `allowWrite`, `allowRead`, `denyRead`, `denyWrite`
        + enforced at OS level with seatbelt/bubblewrap
        + path prefixes determine how paths are resolved:
            + `//` absolute path from fs root
            + `~/` relative to home directory
            + `/` relative to settings file's directory
            + `./` (or no prefix) relative path resolved by sandbox runtime
    * `network`:
        + operates by restricting all domains that processes are allowed to connect to
        + does not otherwise inspect traffic passing through proxy, users are responsible for ensuring they only allow trusted domains in their policy
        + WARNING: be careful of broad domains, like `github.com`, whhich could allow for data exfiltration
        + WARNING: it may be possible to bypass network filtering through `domain fronting`
    * "managed MCP" (not a sandbox option but seems relevant):
        + https://code.claude.com/docs/en/mcp#managed-mcp-configuration
        + takes control of mcp management; users cannot add/modify/use any MCP not defined in `managed-mcp.json`; but this is system setting, not user-space
        + alternatively, policy-based whitelists:
            + `allowedMcpServers` and `deniedMcpServers` configured by either name, url, or command
            + `deniedMcpServers` takes absolute precedence over the allow list

WIP example config:
```jsonc
{
  # first-line of defense
  "permissions": {
    "deny": [
      "Read(**/.env*)",
      "Read(**/secrets/**)",
      "Read(**/*credentials*)",
      "Read(**/*secret*)",
      "Read(~/.ssh/**)",
      "Read(~/.aws/**)",
      "Read(~/.kube/**)",
      "Bash(git push *)",
      "Bash(* install)"
        ],
    # start in plan-mode (no edits)
    "defaultMode": "plan"
    },
    # don't allow it to bypass the permissions
    "disableBypassPermissionsMode": true,
    # don't allow remote sessions to connect
    "allow_remote_sessions": false,
    # use claude's built-in sandboxing
    "sandbox": {
        "enabled": true,
        # don't let clause un-sandbox itself
        "allowUnsandboxedCommands": false,
        "filesystem": {
            "allowRead": [
                "~/my-public-folder-or-whatever"
            ]
        },
        "network": {
            "allowManagedDomainsOnly": true,
            "allowedDomains": [
                "myfriendlydomain.whatever",
                "*.whatever.com"
            ],
            # allow local host binding (macos only).
            # might be dangerous still...
            "allowLocalBinding": true,
            "allowUnixSockets": [
                "/var/run/docker.sock"
            ]
        }
    }
}
```


# opensandbox

TODO: this looks pretty interesting...
