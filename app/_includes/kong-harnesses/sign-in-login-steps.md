Sign in to your profile in an interactive terminal using [`kong-harnesses login`](/kong-harnesses/login/):

1. Run `login` for your profile:

   ```sh
   kong-harnesses login --profile PROFILE_NAME
   ```

   For an identity provider profile, kong-harnesses opens your browser at the identity provider's sign-in page and prints the URL in the terminal.
   Open that URL in a browser on the same computer so the callback reaches kong-harnesses, or add `--no-browser` to print the URL without opening a browser automatically.

   For a static-key profile, `login` prompts for the key from your administrator and hides your input as you type or paste it.
{%- if include.mcp_keys == "true" %}
1. Complete the sign-in and enter any gateway MCP server keys if prompted.
   When the profile already has a usable sign-in, `login` keeps it and asks only for missing gateway MCP server keys.
{%- else %}
1. Complete the sign-in and follow the command in the `Next` field of the output.
{%- endif %}
1. {% if include.mcp_keys == "true" %}Follow the command in the `Next` field and restart {{ include.cli_name }} if it's already running.{% else %}Restart {{ include.cli_name }} if it's already running.{% endif %}
{%- if include.ci_note == "true" %}

{:.info}
> **CI jobs:** A CI profile reads its key from `KONG_HARNESSES_STATIC_KEY` on each request, so `login` refuses it.
> Set `KONG_HARNESSES_STATIC_KEY` in the environment where {{ include.cli_name }} starts instead.
{%- endif %}
