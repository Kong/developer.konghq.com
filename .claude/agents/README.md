# Claude Code agents

Project agents for this repo. Claude Code picks up `.claude/agents/*.md` automatically when you work in a clone of the repo.

## backport-tickets

Lists AI Gateway (`AG` Jira project) tickets titled `[backport]` whose fix version matches `aigw-<major>.<minor>.*`. Read-only: it never edits or transitions tickets.

### Prerequisites

1. **Claude Code CLI**, installed and logged in, at a version that supports `--agent`. Check with `claude --help | grep -- --agent`.
2. **The claude.ai Atlassian Rovo connector**, connected to your Claude account and authorized for `konghq.atlassian.net`. The agent's `tools:` list uses `mcp__claude_ai_Atlassian_Rovo__searchJiraIssuesUsingJql`. If you use a different Atlassian MCP server, change that tool name.
3. **Read access to the `AG` Jira project.** Without it the search returns nothing and the agent reports 0 tickets rather than an auth error.

### Usage

From a clone of this repo, interactively:

```sh
claude --agent backport-tickets
```

Then reply with `version=2.4`.

Or non-interactively:

```sh
claude -p "version=2.3" --agent backport-tickets \
  --allowedTools "mcp__claude_ai_Atlassian_Rovo__searchJiraIssuesUsingJql" "ToolSearch" < /dev/null
```

Flags go in the prompt as `key=value` pairs:

| Flag | Values | Default |
|---|---|---|
| `version` | `X.Y` or `X.Y.Z` (patch matches that exact fix version) | required |
| `format` | `table`, `json`, `md-list` | `table` |
| `status` | comma-separated statuses, such as `Done,In Progress` | all |
| `excluded` | `yes`, `no` | `yes` |

### Conventions it relies on

- The ticket title contains the literal `[backport]`.
- Fix versions are named `aigw-X.Y.Z`.

Tickets on the version without the `[backport]` tag are listed in an "Excluded" note so you can spot mis-titled ones.
