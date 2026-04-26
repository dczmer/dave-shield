minimalist
take control of your context
extensible
self-evolving

What is NOT built in:

- No MCP: use CLI tools + skills
- No sub-agents: tmux + self-spawn
- No plan mode: write to PLAN.md
- No background bash: tmux sessions
- No built in todos: write TODO.md

or build it all yourself, exactly how you like it

extensions: tools, commands, shortcuts, events, tui components
skills: capability packages loaded on demand
project templates: reusable markdown tempaltes with argument support
themes: customizable colors and styling with hot-reload
pi packages: bundle and share everything via git or npm

everything hot-reloads. edit code while pi is running.

---

# TODO:

1. manage the `rtk` extensions (and any others)
2. wrap the pi agent and sandbox it; verify the typescript development still works
3. migrate/support skills and skill-issues project
4. guardrails?
5. subagents and orchestration (extension or spawn with tmux)
6. superpowers-like skills

i can just make a custom pi package with my own collection of themes and extensions.

check out the following extensions:

https://github.com/aliou/pi-guardrails (needs a lot of config)
- this is good, but sooo many dependencies...
- it has more features than i expected
- TODO: look for more lightweight implementation or make your own:
    * `ask` before external file access, list of `allow` patterns
    * list of hard `deny` patterns
    * list of bash patterns to `ask`, `block`
    * no need to 'allow for rest of session`, add command to update and hot-reload config

https://github.com/alisorcorp/pi-small-model-addons (disable all; only enable when using local model)
- install it but keep disabled unless using local llm
- TODO: actually, install it as an input and expose a wrapped pi that uses `-e` to load it

TODO: https://github.com/stagefright5/pi-agent-extensions/tree/main/plan-mode (maybe make your own plan mode instead of using this random package)
or maybe this one instead: https://www.npmjs.com/package/@ifi/pi-plan

https://www.npmjs.com/package/pi-lens
- it auto-installs linters and you cant configure it to ask first
- maybe not necessary or worth it?
- TODO: ?

If you use a Node version manager and want package installs to reuse a stable npm context, set npmCommand in settings.json, for example ["mise", "exec", "node@20", "--", "npm"].

create subagents by spawning more pi instances using all of the command line switches to control options and output format. and you can pass filenames as arguments with `@`.

use `shellCommandPrefix` instead of making the rtk extension? well we need a wrapper script maybe, in case rtk isn't installed.

an extension can dynamically load resource directories when it starts up (except for extensions and other settings).

you can install packages via setup file:
```
{
  "packages": ["pi-skills", "@org/my-extension"]
}
```
that's npm format, use `git:` for github.
you can 'filter' the packages so you only load parts.

TODO: https://github.com/burneikis/pi-vim


I think i'll embrace the "minimal" aspect and keep to only truly critical extensions, and things i make myself.
