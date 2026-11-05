```
Remove one installed connection profile from this computer.

Usage:
  agent-auth-cli profile delete --name <name>

This removes the stored profile document only. It signs nothing out and
changes no client settings, so it refuses while either still refers to the
profile: the document carries the revocation endpoint logout needs, and a
client configured for it would be left pointing at a profile that no longer
exists. Run logout for the profile, and profile cleanup for the client, then
delete it.

One profile document serves every supported client, so the check covers all
of them - claude-code, codex, opencode, and omp - and not only the one a
--client selector scopes this process to. A profile still activated in any
one of them refuses the deletion and names that client. Because that check
has to see every client, delete cannot be combined with
--claude-config-location, which names one Claude settings file and hides the
rest; it refuses instead of deleting on a machine it could not examine.

Deletion is confirmed by typing the exact profile name and needs an
interactive controlling terminal.
```