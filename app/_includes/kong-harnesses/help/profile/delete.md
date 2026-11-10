```ansi
Delete an installed profile from this computer.

This deletes only the saved profile. It does not sign you out and does not
change agent CLI settings. So it refuses while you are still signed in to the
profile, because logout needs the profile to end the sign-in. It also refuses
while an agent CLI still uses the profile, and names that agent CLI. First
run logout for the profile and profile cleanup for the agent CLIs, then
delete the profile.

One profile serves every agent CLI, so the check covers all of them:
claude-code, codex, opencode, and omp, even when --client names only one.

To confirm, you type the profile name. This needs a terminal. --auto-approve
confirms in advance and prints the confirmation to stderr.

Usage:
  kong-harnesses profile delete <name> [flags]

Aliases:
  delete, d, del, rm, D, DEL, RM

Examples:
  # Delete profile work from this computer
  kong-harnesses profile delete work

Flags:
      --auto-approve   delete the profile without asking you to type its name
  -h, --help           help for delete

Global Flags:
      --client client     the one agent client to work on: claude-code, codex, opencode, or omp
      --log-file path     write the debug log to this path instead of stderr
      --log-level level   the log level: trace, debug, info, warn, error; debug and trace also write the debug log (default error)
```