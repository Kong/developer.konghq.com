Sign in to your profile in an interactive terminal using [`kong-harnesses login`](/kong-harnesses/login/):

1. Run `login` for your profile:

   ```sh
   kong-harnesses login --profile PROFILE_NAME
   ```

   For an identity provider profile, kong-harnesses opens your browser at the identity provider's sign-in page and prints the URL in the terminal.
   Open that URL in a browser on the same computer so the callback reaches kong-harnesses, or add `--no-browser` to print the URL without opening a browser automatically.

   For a static-key profile, `login` prompts for the key from your administrator and hides your input as you type or paste it.
1. Complete the sign-in and follow the command in the `Next` field of the output.
1. Restart {{ include.cli_name }} if it's already running.

{:.info}
> **CI jobs:** A CI profile reads its key from `KONG_HARNESSES_STATIC_KEY` on each request, so `login` refuses it.
> Set `KONG_HARNESSES_STATIC_KEY` in the environment where {{ include.cli_name }} starts instead.
