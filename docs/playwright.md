NOTE: claude sandbox mode blocks playwright (technically the browsers) on mac. work-around is basically to tell claude to bypass the sandbox, which means you can't restrict it from bypassing the sandbox mode.

claude's sandbox seems to be more for allowing you to "safely" let claude run w/out prompting for permissions, rather than protecting from a rogue agent.


idea: wrap claude in script to configure playwright? can't the process just UNSET the variables though?
```bash
#!/bin/bash

# NOTE: this env stuff can go in settings.json under `env` key.
# or use PLAYWRIGHT_MCP_CONFIG=/path/to/config and then white-list reading that
export PLAYWRIGHT_MCP_ALLOWED_HOSTS="localhost,127.0.0.1"
export PLAYWRIGHT_MCP_ALLOWED_ORIGINS="haomni-duo1.duo.test;admin-duo1.duo.test"
export PLAYWRIGHT_MCP_ALLOW_UNRESTRICTED_FILE_ACCESS=
export PLAYWRIGHT_MCP_BROWSER=chromium
export PLAYWRIGHT_MCP_SANDBOX=1
claude "$@"
```
