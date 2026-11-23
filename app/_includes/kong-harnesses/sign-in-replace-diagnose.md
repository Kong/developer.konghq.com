Use these commands if you need to switch accounts, rotate a saved static key, or find why a sign-in failed for {{ include.cli_name }}:

* **Replace a working sign-in or saved static key:** Run [`kong-harnesses login`](/kong-harnesses/login/) with `--replace`, then type `PROFILE_NAME` to confirm:

  ```sh
  kong-harnesses login --profile PROFILE_NAME --replace
  ```

  If the profile doesn't have a usable sign-in yet, or if the saved sign-in needs attention, run `kong-harnesses login --profile PROFILE_NAME` without `--replace`.
  For full replacement details, see [Sign in again](/kong-harnesses/sign-in/#sign-in-again).
* **Diagnose a failed sign-in:** Run `login` with `--diagnostics` to report the failing component and reason without printing tokens or sign-in URLs:

  ```sh
  kong-harnesses login --profile PROFILE_NAME --diagnostics
  ```

  For every sign-in, token, `login`, and `logout` error message and fix, see [Sign-in errors in kong-harnesses](/kong-harnesses/sign-in/errors/).
