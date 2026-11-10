```
Set up the installed agent CLIs to use a profile.

Without --client, activate sets up every agent CLI that the profile lists,
that is installed on this computer, and that the gateway has a route for. It
shows the list and asks once before it changes anything, because you may want
to keep an installed agent CLI off the gateway. If one agent CLI on the list
cannot use the profile, activate changes nothing.

With --client, activate sets up only that agent CLI (claude-code, codex,
opencode, or omp), and does not ask about the list.

--auto-approve answers yes in advance, for runs without a terminal.
--dry-run shows the changes without making them, so it asks nothing. With
both, --dry-run wins.

For Claude Code's /cost, the gateway prices need administrator rights to
install. activate asks about this in a terminal. With --auto-approve, it does
not install them.

Before it changes anything, activate sends an empty test request to the
gateway route of each agent CLI. It sends your sign-in with it, except with
--dry-run or for OpenCode. If the gateway has no route, or refuses the
sign-in, every request of that agent CLI would fail. With --client, activate
stops. Without --client, it leaves that agent CLI out and sets up the rest.

When the profile sets no attribution, Claude Code can add custom headers from
its own settings or shell, which the test request does not have. So for
Claude Code a failed check only warns, and the doctor checks at the end try
again with those headers. The test request also cannot copy what only the
agent CLI sends, such as its User-Agent. If your gateway routes on such
values, use --skip-route-check. It sends no test requests, also not in the
doctor checks at the end, and leaves no agent CLI out.

For OpenCode, activate asks the npm registry with your own npm token whether
OpenCode can install the gateway plugin, also with --dry-run. It warns you
before opencode auth login would fail.

At the end, activate runs the doctor checks for each agent CLI it set up, and
shows each problem with its fix. Like doctor, these checks use the network.
They do not change the exit code. --dry-run skips them.

Usage:
  kong-harnesses profile activate <name> [flags]

Examples:
  # Show what activating profile work would change
  kong-harnesses profile activate work --dry-run
  # Set up every installed agent CLI that profile work lists
  kong-harnesses profile activate work
  # Set up only Codex
  kong-harnesses profile activate work --client codex

Flags:
      --auto-approve       set up the listed agent CLIs without asking
      --dry-run            show the changes without making them
  -h, --help               help for activate
      --skip-route-check   do not send test requests to the gateway's routes

Global Flags:
      --client client     the one agent client to work on: claude-code, codex, opencode, or omp
      --log-file path     write the debug log to this path instead of stderr
      --log-level level   the log level: trace, debug, info, warn, error; debug and trace also write the debug log (default error)
```