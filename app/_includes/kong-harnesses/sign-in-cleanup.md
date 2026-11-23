Remove the saved sign-in, static key, and any saved gateway MCP server keys for the profile using [`kong-harnesses logout`](/kong-harnesses/logout/):

```sh
kong-harnesses logout --profile PROFILE_NAME
```

Type `PROFILE_NAME` when prompted to confirm, or pass `--auto-approve` to confirm in advance.
A running session that caches access tokens can keep using its current token until that token expires.
For what `logout` revokes across identity provider, static-key, and CI profiles, see [Sign out](/kong-harnesses/sign-in/#sign-out).
