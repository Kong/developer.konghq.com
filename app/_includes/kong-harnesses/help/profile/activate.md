```
Configure one or every detected agent CLI to use one profile.

Usage:
  agent-auth-cli profile activate --name <name> [--print-only]
  agent-auth-cli profile activate --name <name> --auto [--yes] [--print-only]

The optional process-level --client selector chooses the target: claude-code
(default), codex, opencode, or omp.

--auto configures every agent client detected on this machine, after listing
what it found and asking for confirmation. It cannot be combined with --client
or --claude-config-location, both of which name a single target. Detection is
not consent: an installed client may be one you keep off the gateway
deliberately, so nothing is written until the list is confirmed. --yes
confirms in advance for unattended use, and --print-only needs no confirmation
because it changes no file. Every detected client is previewed first, so a
profile one of them cannot use refuses the whole run instead of configuring
the rest.

For the opencode target, activation, including --print-only, asks the npm
registry, with your own npm token, whether OpenCode can install the gateway
plugin, and warns before opencode auth login would fail.

Activating one target ends by running doctor's checks for the profile and
printing the findings that are not ok, each with its fix when it has one. Like
doctor, that connects to the issuer and the gateway. The findings do not
change the exit code. --print-only runs no checks, and --auto runs them for
Claude Code only.
```