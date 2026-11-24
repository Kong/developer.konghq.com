---
title: Sign-in errors in kong-harnesses
description: Diagnostics and error reference for kong-harnesses credential, token, login, and logout commands, with causes and fixes.

content_type: reference
layout: reference

tools:
  - kong-harnesses

tags:
  - ai
  - authentication
  - cli
  - errors
  - troubleshooting

breadcrumbs:
  - /kong-harnesses/
  - /kong-harnesses/sign-in/

related_resources:
  - text: Sign in with kong-harnesses
    url: /kong-harnesses/sign-in/
  - text: kong-harnesses login
    url: /kong-harnesses/login/
  - text: kong-harnesses logout
    url: /kong-harnesses/logout/
  - text: kong-harnesses doctor
    url: /kong-harnesses/doctor/
---

When a sign-in, token, or logout command fails, kong-harnesses prints a line that starts with `Error:` and often names the next command to run.
Replace `PROFILE_NAME` with your installed profile name in each command.
For sign-in and sign-out steps, see [Sign in with kong-harnesses](/kong-harnesses/sign-in/).

## Diagnose a failed sign-in

When [`kong-harnesses login`](/kong-harnesses/login/) fails and its error line doesn't explain why, run `login` with `--diagnostics`:

```sh
kong-harnesses login --profile PROFILE_NAME --diagnostics
```

`login --diagnostics` reports the failing component and reason, such as an unsupported token lifetime, a missing refresh token, or an unavailable secret store, without printing access tokens or sign-in URLs.
When the profile doesn't have a usable sign-in, `login --diagnostics` attempts to sign in, which can ask to remove a damaged sign-in and open your browser.
When the sign-in is already ready, `login --diagnostics` doesn't send a sign-in request, though it still prompts for any missing gateway MCP server keys.
Don't combine `--diagnostics` with `--no-browser` or `--replace`.

## When kong-harnesses can't give an access token

When [`kong-harnesses credential`](/kong-harnesses/credential/) can't give {{ site.claude_code }} an access token, it prints one line starting with `Error:` that {{ site.claude_code }} shows.
[`kong-harnesses token`](/kong-harnesses/token/), [`status`](/kong-harnesses/status/), and [`login`](/kong-harnesses/login/) print the same lines for matching failures.
[`logout`](/kong-harnesses/logout/) prints them for secret store failures, for a saved sign-in that needs attention, and when another command uses the profile.
Commands that load the profile store can also print `profile storage is unavailable` or `the profiles in FOLDER could not be moved`.

The following table lists the start of each line after `Error:`:

{% table %}
columns:
  - title: Message
    key: message
  - title: Cause
    key: cause
  - title: What to do
    key: fix
rows:
  - message: "`sign-in needs attention`"
    cause: >-
      The sign-in expired, the identity provider revoked it, or the saved sign-in can't be used.
      From `logout`, this line can also mean that `logout` couldn't release its lock on the profile.
    fix: >-
      When `logout` prints this line, run `kong-harnesses logout --profile PROFILE_NAME` again instead of signing in again.
      For other commands, run `kong-harnesses login --profile PROFILE_NAME`.
  - message: "`the last renewal of this sign-in did not finish`"
    cause: >-
      A renewal stopped before it finished.
      The saved sign-in still works.
    fix: >-
      Nothing: the next request resumes the renewal.
      If requests keep failing, run `kong-harnesses login --profile PROFILE_NAME` (the old sign-in stays intact if the new attempt fails).
  - message: "`the sign-in server cannot be reached`"
    cause: kong-harnesses can't reach the identity provider.
    fix: "Check your network or VPN, or run [`kong-harnesses doctor --profile PROFILE_NAME`](/kong-harnesses/doctor/)."
  - message: "`no browser opened to sign in`"
    cause: kong-harnesses couldn't open a browser for the first sign-in, and the callback address didn't receive a sign-in result.
    fix: >-
      Open the printed sign-in URL in a browser on the same computer while kong-harnesses waits.
      If the attempt timed out, run `kong-harnesses login --profile PROFILE_NAME --no-browser` in a terminal to get a new URL.
  - message: "`another kong-harnesses command, such as a sign-in or a renewal, is using this profile`"
    cause: Another kong-harnesses command uses the profile, such as a sign-in waiting for the browser.
    fix: Try again when the other command finishes.
  - message: "`another program on this computer, such as another developer's sign-in, is using the sign-in callback address`"
    cause: Another program on this computer uses the callback port, such as another developer's sign-in on a shared computer.
    fix: Wait for the other sign-in to finish, or stop the program using the callback port, then try again.
  - message: "`this profile has no saved key`"
    cause: The profile uses a static key from your administrator, and this computer doesn't have the key yet.
    fix: "Run `kong-harnesses login --profile PROFILE_NAME` and enter the key from your administrator."
  - message: "`profile \"PROFILE_NAME\" reads its key from KONG_HARNESSES_STATIC_KEY`"
    cause: >-
      The profile reads its key from the environment, as in a CI job.
      From `credential` or `token`, `KONG_HARNESSES_STATIC_KEY` isn't set to a valid key.
      From `login`, kong-harnesses doesn't save environment keys.
    fix: "Set `KONG_HARNESSES_STATIC_KEY` in the environment where the agent CLI starts, and don't run `login` for this profile."
  - message: "`a proxy is set for the plain-HTTP gateway GATEWAY_URL`"
    cause: >-
      The profile uses a local `http://` gateway and a proxy variable (even an invalid one) applies to the gateway host, where the proxy could read the access token.
    fix: >-
      Add the gateway host to `NO_PROXY` and `no_proxy` in your shell (for IPv6, add every form named in the error, such as `[::1]:8000,[::1],::1`), or switch to an `https://` gateway.
      For {{ site.claude_code }}, run `kong-harnesses doctor --profile PROFILE_NAME --client claude-code` from your project folder, follow its proxy steps, run `kong-harnesses profile activate PROFILE_NAME --client claude-code`, and restart {{ site.claude_code }}.{% comment %}
      For omp and pi, set those exclusions in the shell that starts the CLI.
      Codex, OpenCode, and Hermes Agent require an `https://` gateway.{% endcomment %}
  - message: "`the profiles in FOLDER could not be moved to FOLDER`"
    cause: kong-harnesses couldn't move the profiles of an earlier release to their new folder.
    fix: Move the profile folder to the path named in the error, then try again.
  - message: "`profile storage could not be read`"
    cause: kong-harnesses can't open the profile folder or read the profile file.
    fix: "Verify your user permissions on the profile folder and file, then run [`kong-harnesses profile list`](/kong-harnesses/profile/list/)."
  - message: "`this profile uses your own Claude subscription`"
    cause: "{{ site.claude_code }} sends its own Claude sign-in to the model, so `credential` doesn't give it a token."
    fix: >-
      Sign in to Claude inside {{ site.claude_code }} with `/login`.
      `kong-harnesses login --profile PROFILE_NAME` still signs you in for your gateway identity.
  - message: "`credential operation cancelled before access-token output`, `token operation cancelled before access-token output`, or `token operation cancelled before credential use`"
    cause: The request stopped before kong-harnesses wrote the token.
    fix: Try again.
  - message: "`access token output could not be prepared` or `access token output could not be completed`"
    cause: kong-harnesses received a token but couldn't write it to standard output, for example because the agent CLI closed the pipe.
    fix: Restart the agent CLI and try again, or keep the read end of a script's pipe open until the command exits.
  - message: "`fresh login is required`"
    cause: >-
      `token` never opens a browser, and the saved sign-in is missing, expired, damaged, mismatched, rejected on renewal, or returned an invalid bearer token.
    fix: "Run `kong-harnesses login --profile PROFILE_NAME`."
  - message: "`credential operation could not complete` or `token operation could not complete`"
    cause: kong-harnesses stopped without a more specific error, for example after a failed browser sign-in.
    fix: >-
      Run `kong-harnesses login --profile PROFILE_NAME` in a terminal.
      If `login` fails, run `kong-harnesses login --profile PROFILE_NAME --diagnostics` or `kong-harnesses doctor --profile PROFILE_NAME`.
{% endtable %}

Errors about the secret store, the session, the profile folder, and the callback address depend on the operating system:

{% navtabs "access-token-os-errors" %}
{% navtab "macOS" %}
{% table %}
columns:
  - title: Message
    key: message
  - title: Cause
    key: cause
  - title: What to do
    key: fix
rows:
  - message: "`your Keychain is locked`"
    cause: The Keychain is locked.
    fix: "Run `security unlock-keychain`, then try again."
  - message: "`your Keychain does not yet let this kong-harnesses build read your sign-in`"
    cause: Keychain doesn't trust this kong-harnesses build yet, for example after an upgrade.
    fix: "Run `kong-harnesses login --profile PROFILE_NAME` and click **Always Allow** on each Keychain prompt."
  - message: "`profile storage is unavailable, because HOME is not set to an absolute path`"
    cause: "`HOME` isn't set to an absolute path."
    fix: "Set `HOME` to your home folder, then try again."
{% endtable %}
{% endnavtab %}
{% navtab "Linux" %}
{% table %}
columns:
  - title: Message
    key: message
  - title: Cause
    key: cause
  - title: What to do
    key: fix
rows:
  - message: "`your system password store is locked`"
    cause: The keyring is locked.
    fix: Unlock the keyring, then try again.
  - message: "`your system password store refused access to your sign-in`"
    cause: The system password store refused access to the sign-in.
    fix: "Run `kong-harnesses login --profile PROFILE_NAME`."
  - message: "`no Secret Service runs in this session`"
    cause: The session doesn't have a keyring.
    fix: "Use a desktop session with a keyring, such as GNOME Keyring or KWallet, or use a `KONG_HARNESSES_STATIC_KEY` profile in CI."
  - message: "`this session has no per-user runtime directory (XDG_RUNTIME_DIR)`"
    cause: "`XDG_RUNTIME_DIR` isn't set to an absolute path, for example in a container or CI job (`logout` also prints this line)."
    fix: "Create a private directory with `install -d -m 0700 RUNTIME_DIR` and set `XDG_RUNTIME_DIR` to its absolute path."
  - message: "`profile storage is unavailable, because XDG_CONFIG_HOME is not an absolute path, or it is unset and HOME is not`"
    cause: "`XDG_CONFIG_HOME` is a relative path, or it's unset and `HOME` isn't an absolute path."
    fix: "Set `XDG_CONFIG_HOME` to an absolute path, or unset it and set `HOME`, then try again."
{% endtable %}
{% endnavtab %}
{% navtab "Windows" %}
{% table %}
columns:
  - title: Message
    key: message
  - title: Cause
    key: cause
  - title: What to do
    key: fix
rows:
  - message: "`Windows cannot save or read your sign-in in this session`"
    cause: The session can't use DPAPI, for example a key-authenticated SSH session.
    fix: Use your desktop session (where you set up kong-harnesses) or a password-authenticated SSH session.
  - message: "`your system password store refused access to your sign-in`"
    cause: The system password store refused access to the sign-in.
    fix: "Run `kong-harnesses login --profile PROFILE_NAME`."
  - message: "`profile storage is unavailable, because AppData is not set to an absolute path`"
    cause: "`AppData` isn't set to an absolute path."
    fix: "Set `AppData` to your roaming application data folder, then try again."
  - message: "`another program on this computer, such as another developer's sign-in, is using the sign-in callback address, or Windows reserved that port`"
    cause: Windows reserved the callback port, or another program on this computer uses it.
    fix: >-
      Find the port in `Redirect URI` using `kong-harnesses profile get PROFILE_NAME`, then check reserved ports with `netsh interface ipv4 show excludedportrange protocol=tcp` and `netsh interface ipv6 show excludedportrange protocol=tcp`.
      If Windows reserved the port, ask your administrator for a profile with a registered free port, import and activate it, and sign in again.
{% endtable %}
{% endnavtab %}
{% endnavtabs %}

When a line starts with `selected profile`, run [`kong-harnesses profile list`](/kong-harnesses/profile/list/) to see the installed profiles.

## When the login or logout command fails

When `login` or `logout` can't finish, it prints one line starting with `Error:`.
The following table lists the lines printed only by `login` and `logout`{% comment %}, and the refusal messages for agent CLIs that sign in through their own plugin{% endcomment %}:

{% table %}
columns:
  - title: Message
    key: message
  - title: Cause
    key: cause
  - title: What to do
    key: fix
rows:{% comment %}
  - message: "`OpenCode owns authentication`"
    cause: "You ran `login`, `logout`, `credential`, or `token` with `--client opencode`."
    fix: "Follow [Sign in to OpenCode with kong-harnesses](/kong-harnesses/sign-in/opencode/)."
  - message: "`the Kong AI Gateway plugin owns authentication for Hermes`"
    cause: "You ran `login`, `logout`, `credential`, or `token` with `--client hermes`."
    fix: "Follow [Sign in to Hermes Agent with kong-harnesses](/kong-harnesses/sign-in/hermes/)."{% endcomment %}
  - message: "`login requires an interactive controlling terminal` or `logout asks you to type the profile name, so it needs an interactive controlling terminal`"
    cause: "`login` or `logout` ran without a terminal, for example in a script or CI job."
    fix: >-
      Run the command in an interactive terminal, or pass `--auto-approve` to `logout`.
      In CI, use a `KONG_HARNESSES_STATIC_KEY` profile and don't run `login`.
  - message: "`login accepts only one mode flag`"
    cause: "`login` received both `--replace` and `--diagnostics`."
    fix: "Run `login` with one of the two flags."
  - message: "`login cannot combine --diagnostics with --no-browser`"
    cause: "`--diagnostics` doesn't print the sign-in URL, so it can't be used with `--no-browser`."
    fix: "Run `login --diagnostics` without `--no-browser`."
  - message: "`no usable login exists`"
    cause: "`login --replace` didn't find a saved sign-in or key to replace."
    fix: "Run `kong-harnesses login --profile PROFILE_NAME`."
  - message: "`local sign-in disabled; server sign-out unconfirmed`"
    cause: >-
      `logout` disabled the local sign-in.
      It couldn't confirm that the identity provider revoked all authorizations for the profile, or it found an older sign-in copy that it couldn't read.
    fix: >-
      Run `kong-harnesses status --profile PROFILE_NAME`.
      Revoke any active authorization at your identity provider, even if a later `logout` shows `Already signed out`.
      Then run `kong-harnesses logout --profile PROFILE_NAME` again.
  - message: "`server sign-out confirmed; local cleanup incomplete`"
    cause: The identity provider confirmed revocation, but kong-harnesses couldn't finish removing local files or releasing the profile lock.
    fix: "Run `kong-harnesses logout --profile PROFILE_NAME` again."
  - message: "`local cleanup incomplete; logout did not contact the server`"
    cause: "`logout` skipped server revocation (no saved sign-in, no revocation endpoint, or static-key profile) and couldn't remove all local entries."
    fix: "Run `kong-harnesses logout --profile PROFILE_NAME` again."
  - message: "`saved sign-in needs attention and server state is unknown`"
    cause: "The saved sign-in or key can't be used, `logout` couldn't remove it locally, and `logout` didn't contact the identity provider."
    fix: >-
      Run `kong-harnesses status --profile PROFILE_NAME`, then run `kong-harnesses logout --profile PROFILE_NAME` again.
      For identity provider profiles, also check the authorization at your identity provider.
  - message: "`logout cancelled before completion`"
    cause: "`logout` stopped before it finished, for example because you cancelled the confirmation."
    fix: "Run `kong-harnesses logout --profile PROFILE_NAME` again."
  - message: "`logout could not complete`"
    cause: "`logout` stopped without a more specific error."
    fix: "Check status with `kong-harnesses status --profile PROFILE_NAME`, then run `logout` again."
  - message: "`login result could not be written`, `logout result could not be written`, or `diagnostic report could not be written`"
    cause: The command couldn't write its output, for example because the terminal closed, sometimes after changing the sign-in.
    fix: "Check `kong-harnesses status --profile PROFILE_NAME` before running the command again."
  - message: "`login could not complete`"
    cause: "`login` stopped without a more specific error."
    fix: "Run `kong-harnesses login --profile PROFILE_NAME --diagnostics` to find the cause."
  - message: "`login cancelled; no usable login was created`"
    cause: "The sign-in or confirmation stopped, sometimes after `login` saved the sign-in."
    fix: >-
      Check `kong-harnesses status --profile PROFILE_NAME`.
      Run `kong-harnesses login --profile PROFILE_NAME` again in an interactive terminal if `Login` isn't `Ready` or if gateway MCP server keys are missing.
  - message: "`the sign-in is saved, but a gateway MCP server has no key yet`"
    cause: "`login` saved the sign-in, but you cancelled the gateway MCP server key prompt, it timed out, or the key you entered wasn't valid."
    fix: "Run `kong-harnesses login --profile PROFILE_NAME` again to add the key."
  - message: "`the sign-in is saved, but the system password store did not save the key of a gateway MCP server`"
    cause: The system password store couldn't read, remove, or save the key, for example because it's locked.
    fix: "Unlock the system password store if it's locked, then run `kong-harnesses login --profile PROFILE_NAME`."
{% endtable %}

When `login` can't read a saved gateway MCP server key, the message depends on the operating system:

{% navtabs "gateway-mcp-key-errors" %}
{% navtab "macOS" %}
{% table %}
columns:
  - title: Message
    key: message
  - title: Cause
    key: cause
  - title: What to do
    key: fix
rows:
  - message: "`your Keychain does not let this kong-harnesses build read the saved key of the gateway MCP server`"
    cause: Keychain doesn't let this kong-harnesses build read the key, for example because you clicked **Allow** instead of **Always Allow**.
    fix: "Run `kong-harnesses login --profile PROFILE_NAME` again and click **Always Allow** when Keychain prompts."
{% endtable %}
{% endnavtab %}
{% navtab "Linux and Windows" %}
{% table %}
columns:
  - title: Message
    key: message
  - title: Cause
    key: cause
  - title: What to do
    key: fix
rows:
  - message: "`your system password store did not let kong-harnesses read the saved key of the gateway MCP server`"
    cause: The system password store refused to return the key, for example because it's locked.
    fix: "Unlock the system password store, or run `kong-harnesses login --profile PROFILE_NAME` again."
{% endtable %}
{% endnavtab %}
{% endnavtabs %}
