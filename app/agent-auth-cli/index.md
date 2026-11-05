---
title: agent-auth-cli
description: Reference for the agent-auth-cli commands that obtain short-lived OIDC access tokens for coding agents.

content_type: reference
layout: reference

tools:
  - agent-auth-cli
---

agent-auth-cli obtains short-lived OIDC access tokens for coding agents such as Claude Code, Codex, OpenCode, and omp. It manages connection profiles, signs in to an OIDC identity provider, and configures the agent CLI to route its traffic through the gateway.

Each command page shows the help text from the installed binary.

## Commands

- [agent-auth-cli credential](/agent-auth-cli/credential/): Return one access token, creating the first login when absent.
- [agent-auth-cli doctor](/agent-auth-cli/doctor/): Check one profile end to end and report each fix beside each finding.
- [agent-auth-cli login](/agent-auth-cli/login/): Sign in to, repair, or diagnose one profile.
- [agent-auth-cli logout](/agent-auth-cli/logout/): Sign out of one profile and remove its saved sign-in.
- [agent-auth-cli profile](/agent-auth-cli/profile/): Manage public connection profiles and Claude integration.
- [agent-auth-cli setup](/agent-auth-cli/setup/): Import one profile, sign in, and configure the client, in one run.
- [agent-auth-cli status](/agent-auth-cli/status/): Inspect one profile's local login and client activation state.
- [agent-auth-cli statusline](/agent-auth-cli/statusline/): Render one status-bar line from a client's session document.
- [agent-auth-cli token](/agent-auth-cli/token/): Print one access token for an explicit connection profile.

## Profile subcommands

- [agent-auth-cli profile create](/agent-auth-cli/profile/create/): Build and install a profile using OIDC discovery.
- [agent-auth-cli profile import](/agent-auth-cli/profile/import/): Install a complete profile from a file or HTTPS URL.
- [agent-auth-cli profile list](/agent-auth-cli/profile/list/): List installed profiles.
- [agent-auth-cli profile show](/agent-auth-cli/profile/show/): Show one installed profile's public configuration.
- [agent-auth-cli profile activate](/agent-auth-cli/profile/activate/): Configure one or every detected agent CLI to use one profile.
- [agent-auth-cli profile cleanup](/agent-auth-cli/profile/cleanup/): Remove settings still owned by agent-auth-cli.
- [agent-auth-cli profile delete](/agent-auth-cli/profile/delete/): Remove one installed profile from this computer.
