# FEATURES WHAT I BE WANTING

- agent is locked down to minimum access that it needs:
    * Filesystem:
        + R/W to project dir
        + R/W to agent's manged dirs (config, state, etc)
    * Network:
        + localhost
        + white-list of domains i manage
        + only http/https
    * NPM:
        + disable post-install scripts
        + disable all network access
    * Playwright MCP/CLI:
        + localhost
        + white-list of domains i manage (separate from network white-list; maybe add to that list as a base)
    * Tools/executables:
        + White-list or run in pure package with only tools provided by flake definition
    * Ensure required security configs are applied to agent
    * Can't invoke the unrestricted/human dev shell
    * Auditing of everything the agent tries to do on the system: fs access (outside of cwd), network access (agent + tools), shell commands, etc.
- (human) interactive dev shell:
    * NPM:
        + disable post-install scripts
        + enable network access to install and update packages (don't let the agent do it)
    * Tools/executables:
        + Same tools available to the agent shell
        + Anything else i need to manage, or don't trust the agent to use
- then wrap the agent environment into a application we can `nix run` directly

# Inspiration

https://dev.to/andersonjoseph/how-i-run-llm-agents-in-a-secure-nix-sandbox-1899
https://alexdav.id/projects/jail-nix/
https://fast.io/resources/ai-agent-sandbox-environment/
for work/claude: https://code.claude.com/docs/en/sandboxing
https://open-sandbox.ai/

# Isolation methods to try

I think we need a full network proxy, not just to neuter npm/playwright/agent. AIs is smarts, they might just use `curl | sh` or something.

1. Full VM
2. Containers
3. microvm
4. jail.nix / bubblewrap
5. gVisor
6. compsec / apparmor
7. kata containers
8. env bound to local proxy w/ egress filtering? can i do that with ssh+socks or maybe squid?

## jail.nx / bubblewrap

this was easy to setup and configure for filesystem and execution environment isolation.

it doesn't seem to provide application-level firewall for network restrictions though.

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
