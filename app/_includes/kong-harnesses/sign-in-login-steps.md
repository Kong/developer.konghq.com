Sign in to your profile in an interactive terminal:

1. Run [`kong-harnesses login`](/kong-harnesses/login/) for your profile:

   ```sh
   kong-harnesses login --profile {{ include.profile | default: "PROFILE_NAME" }}
   ```

   For an identity provider profile, kong-harnesses opens your browser at the identity provider's sign-in page and prints the URL in the terminal.
   Open that URL in a browser on the same computer so the callback reaches kong-harnesses, or add `--no-browser` to print the URL without opening a browser.

   For a static-key profile, `login` prompts for the key from your administrator and hides your input as you type or paste it.
1. Complete the sign-in and enter any gateway MCP server keys if prompted.
1. Follow the command in the `Next` field and restart {{ include.cli_name }} if it's already running.
