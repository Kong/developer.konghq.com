Remove the saved sign-in and any saved gateway MCP server keys for the profile using [`kong-harnesses logout`](/kong-harnesses/logout/):

```sh
kong-harnesses logout --profile PROFILE_NAME
```

Type `PROFILE_NAME` when prompted to confirm.
For what `logout` revokes, see [kong-harnesses logout](/kong-harnesses/logout/).
