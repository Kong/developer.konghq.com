{{ include.cli_name }} gets access tokens from [`kong-harnesses token`](/kong-harnesses/token/), which doesn't open a browser.
Run [`kong-harnesses login`](/kong-harnesses/login/) in an interactive terminal before you start {{ include.cli_name }}.

1. Sign in to your profile:

   ```sh
   kong-harnesses login --profile PROFILE_NAME
   ```

   For an identity provider profile, kong-harnesses opens your browser at the identity provider's sign-in page and prints the URL in the terminal.
   Open that URL in a browser on the same computer so the callback reaches kong-harnesses.
   To print the URL without opening a browser automatically, add `--no-browser`.

   For a static-key profile, `login` prompts for the key from your administrator and hides your input as you type or paste it.
1. Complete the sign-in and follow the command in the `Next` field of the output.
1. Restart {{ include.cli_name }} if it's already running.

{:.info}
> **CI jobs:** A CI profile reads its key from `KONG_HARNESSES_STATIC_KEY` on each request, so `login` refuses it.
> Set `KONG_HARNESSES_STATIC_KEY` in the environment where {{ include.cli_name }} starts instead.

On macOS, run `kong-harnesses login --profile PROFILE_NAME` once after each upgrade of kong-harnesses.
Each time Keychain asks whether kong-harnesses can use your sign-in, click **Always Allow**.
