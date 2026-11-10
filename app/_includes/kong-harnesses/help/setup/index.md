```ansi
Install or create a profile, sign in, and set up the agent CLIs, all in one
run.

setup runs these three commands in this order, and asks the same questions
they ask:

  kong-harnesses profile import <source>   (or profile create, without <source>)
  kong-harnesses login --profile <name> [--no-browser]
  kong-harnesses profile activate <name> [--auto-approve] [--skip-route-check]

<source> is a profile file or an HTTPS URL. With <source>, setup shows the
gateway and identity provider of the profile, and asks you to type the
profile name before it installs it. Without <source>, setup asks the
questions of profile create, which needs a terminal.

Without --client, setup sets up every installed agent CLI that the profile
lists, as profile activate does. --auto-approve answers yes to the import and
to the agent CLI list, and prints the import summary to stderr. With a
<source>, only the sign-in is then left. OpenCode has its own sign-in, so
setup skips the sign-in when OpenCode is the only agent CLI. With
--no-browser, open the printed URL in a browser on this computer.

You can run setup again safely. It does not import a profile file that is
already installed with the same content, keeps a sign-in that still works,
and leaves an agent CLI that is already set up. If a step fails, setup stops
and names the step. Run the same command again to continue from there. If the
gateway or this computer refuses an agent CLI, setup names it with the fix.

After setup, use login to fix a sign-in, profile activate to switch profiles,
and profile cleanup to undo the setup.

Usage:
  kong-harnesses setup [source] [flags]

Examples:
  # Set up with a profile URL from your admin
  kong-harnesses setup <profile-url>
  # Set up without one, and answer questions to create a profile
  kong-harnesses setup
  # Set up from a file, and answer yes to every question
  kong-harnesses setup work.json --auto-approve

Flags:
      --auto-approve       install the profile and set up the listed agent CLIs without asking
  -h, --help               help for setup
      --no-browser         print the sign-in URL instead of opening a browser; open the URL on this computer
      --skip-route-check   do not send test requests to the gateway's routes

Global Flags:
      --client client     the one agent client to work on: claude-code, codex, opencode, or omp
      --log-file path     write the debug log to this path instead of stderr
      --log-level level   the log level: trace, debug, info, warn, error; debug and trace also write the debug log (default error)
```