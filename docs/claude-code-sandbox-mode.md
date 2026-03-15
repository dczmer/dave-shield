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
