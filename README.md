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

# Isolation methods to try

1. Full VM
2. Containers
3. microvm
4. jail.nix / bubblewrap
5. gVisor
6. compsec / apparmor
7. kata containers
8. env bound to local proxy w/ egress filtering? can i do that with ssh+socks or maybe squid?
