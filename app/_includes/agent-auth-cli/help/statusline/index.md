```
Render one status-bar line for the client that invokes it.

The client writes its session document to stdin and displays what this writes
to stdout. Configure it in Claude Code's settings as the statusLine command:

  "statusLine": {"type": "command", "command": "agent-auth-cli statusline --name <name>"}

Usage:
  agent-auth-cli statusline --name <name>
```