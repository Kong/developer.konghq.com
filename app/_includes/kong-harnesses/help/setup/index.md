```
Import one profile, sign in, and configure the client, in one run.

Usage:
  agent-auth-cli setup <source> [--no-browser] [--auto [--yes]]
  agent-auth-cli --client <name> setup <source> [--no-browser]

setup runs what these three commands do, in this order, and prompts as they
do:

  agent-auth-cli profile import <source>
  agent-auth-cli login --name <name> [--no-browser]
  agent-auth-cli profile activate --name <name> [--auto [--yes]]

<name> is the profile name the source carries. Import shows the gateway and
identity provider the profile names and asks for the exact profile name
before it installs anything.

<source> is a local profile file or an HTTPS URL. --yes confirms only the
automatic client selection. OpenCode uses its own sign-in, so setup skips
CLI sign-in when --client opencode is selected or --auto detects only OpenCode.
With --no-browser, open the printed URL on this computer to complete sign-in.

setup is safe to run again. A local source already installed with the same
content is not imported again, a usable sign-in is left alone, and a client
already configured is left unchanged. It stops at the first step that fails
and says which one; running the same setup command again resumes there.

The three commands remain for what comes after: login when a sign-in needs
attention, profile activate to switch profiles, and profile cleanup to undo
activation.
```