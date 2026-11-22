---
title: Sign-in errors in kong-harnesses
description: Error messages from kong-harnesses credential, token, login, and logout commands, with causes and fixes.

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
  - text: kong-harnesses errors and exit codes
    url: /kong-harnesses/errors/
  - text: kong-harnesses login
    url: /kong-harnesses/login/
  - text: kong-harnesses logout
    url: /kong-harnesses/logout/
  - text: kong-harnesses doctor
    url: /kong-harnesses/doctor/
---

When a sign-in, token, or logout command fails, kong-harnesses prints a line that starts with `Error:` and often names the next command to run.
Replace `PROFILE_NAME` with the name of your installed profile in each command on this page.
For sign-in and sign-out steps, see [Sign in with kong-harnesses](/kong-harnesses/sign-in/).
For exit codes and other command errors, see [kong-harnesses errors and exit codes](/kong-harnesses/errors/).

## When kong-harnesses can't give an access token

When the [`credential`](/kong-harnesses/credential/) command can't give {{ site.claude_code }} an access token, it prints one line that starts with `Error:`, and {{ site.claude_code }} shows that line.
The line says what's wrong, and many lines also say what to run.
The following table lists the start of each line after `Error:`.
When the browser doesn't open for a first sign-in, kong-harnesses prints the sign-in URL and waits.
If the callback doesn't receive a sign-in result, kong-harnesses prints `no browser opened to sign in`.
{{ site.claude_code }} can show only part of this output.
Open the sign-in URL in a browser on the same computer while kong-harnesses waits for the sign-in.
If the attempt ends, run `kong-harnesses login --profile PROFILE_NAME --no-browser` to get a new URL.

In a terminal, [`token`](/kong-harnesses/token/), [`status`](/kong-harnesses/status/) and [`login`](/kong-harnesses/login/) print the same line for many of these problems.
Commands that load the profile store can print the `profile storage is unavailable` and `the profiles in FOLDER could not be moved` lines, because kong-harnesses checks the profile folder before the command runs.
[`logout`](/kong-harnesses/logout/) prints the same line when the secret store refuses access to the sign-in or doesn't run in the session, when the saved sign-in needs attention, and when another kong-harnesses command uses the profile.

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
      From `logout`, the line can also mean that `logout` couldn't release its lock on the profile.
    fix: >-
      When `logout` prints this line, run `kong-harnesses logout --profile PROFILE_NAME` again.
      A new sign-in would only give `logout` one more authorization to revoke.
      For the other commands, run `kong-harnesses login --profile PROFILE_NAME`.
  - message: "`the last renewal of this sign-in did not finish`"
    cause: >-
      A renewal stopped before it finished.
      The saved sign-in still works.
    fix: >-
      Nothing: the next request resumes the renewal.
      If requests keep failing, run `kong-harnesses login --profile PROFILE_NAME`.
      If the new sign-in fails, the old one stays as it was.
  - message: "`the sign-in server cannot be reached`"
    cause: kong-harnesses can't reach the identity provider.
    fix: "Check your network or VPN, or run [`kong-harnesses doctor --profile PROFILE_NAME`](/kong-harnesses/doctor/)."
  - message: "`no browser opened to sign in`"
    cause: kong-harnesses couldn't open a browser for the first sign-in, and the callback address didn't receive a sign-in result.
    fix: >-
      Run `kong-harnesses login --profile PROFILE_NAME` in a terminal.
      The terminal prints the sign-in URL.
  - message: "`another kong-harnesses command, such as a sign-in or a renewal, is using this profile`"
    cause: Another kong-harnesses command uses the profile, such as a sign-in that waits for the browser.
    fix: Try again when the other command finishes.
  - message: "`another program on this computer, such as another developer's sign-in, is using the sign-in callback address`"
    cause: Another program on this computer uses the callback address of the profile, such as another developer's sign-in on a shared computer.
    fix: >-
      If another sign-in uses the address, wait until it finishes.
      Otherwise, stop the program that uses the port of the callback address.
      Then try again.
  - message: "`this profile has no saved key`"
    cause: The profile uses a key from your administrator, and this computer doesn't have the key yet.
    fix: "Run `kong-harnesses login --profile PROFILE_NAME`, and enter the key from your administrator."
  - message: "`profile \"PROFILE_NAME\" reads its key from KONG_HARNESSES_STATIC_KEY`"
    cause: >-
      The profile reads its key from the environment, as in a CI job.
      From `credential` or `token`, `KONG_HARNESSES_STATIC_KEY` isn't set to a valid key.
      From `login`, the line says that there is nothing to log in to, because kong-harnesses doesn't save this key.
    fix: >-
      Set `KONG_HARNESSES_STATIC_KEY` to the key from your administrator in the environment where the agent CLI starts.
      Don't run `login` for this profile.
  - message: "`a proxy is set for the plain-HTTP gateway GATEWAY_URL`"
    cause: >-
      The profile uses an `http://` gateway on this computer, and a proxy variable, even one with a value that isn't valid, applies to the gateway host where the agent CLI starts.
      The proxy could read the access token.
    fix: >-
      Add the gateway host to `NO_PROXY` in your shell, and also to `no_proxy` if it's set.
      For a gateway at an IPv6 address, add each form that the line names, such as `[::1]:8000,[::1],::1`, because clients read an IPv6 address in `NO_PROXY` differently.
      For {{ site.claude_code }}, run `kong-harnesses doctor --profile PROFILE_NAME --client claude-code` from the project folder, and follow its proxy steps, because project and managed settings can override the exclusions or stop the activation.
      Then run `kong-harnesses profile activate PROFILE_NAME --client claude-code` again, so that its settings exclude the gateway from the proxy, and restart {{ site.claude_code }}.
      For omp and pi, set the same exclusions where the agent CLI starts.
      Codex, OpenCode and Hermes Agent need an `https://` gateway, because kong-harnesses doesn't set them up for an `http://` gateway.
      You can also use an `https://` gateway.
      Then try again.
  - message: "`the profiles in FOLDER could not be moved to FOLDER`"
    cause: kong-harnesses couldn't move the profiles of an earlier release to their new folder.
    fix: Move the profile folder to the path that the line gives, then run the command again.
  - message: "`profile storage could not be read`"
    cause: kong-harnesses can't open the folder that contains its profiles, or it can't read the profile file.
    fix: >-
      Make sure that your user can open the profile folder and read the profile file, then try again.
      To check the profiles, run [`kong-harnesses profile list`](/kong-harnesses/profile/list/).
  - message: "`this profile uses your own Claude subscription`"
    cause: >-
      The profile uses your own Claude subscription.
      {{ site.claude_code }} sends its own Claude sign-in to the model, so `credential` doesn't give it a token.
    fix: >-
      Sign in to Claude in {{ site.claude_code }} with `/login`.
      `kong-harnesses login --profile PROFILE_NAME` still signs you in for your identity at the gateway.
  - message: "`credential operation cancelled before access-token output`, `token operation cancelled before access-token output`, or `token operation cancelled before credential use`"
    cause: The request stopped before kong-harnesses wrote the token.
    fix: Try again.
  - message: "`access token output could not be prepared` or `access token output could not be completed`"
    cause: kong-harnesses got a token, but it couldn't prepare or complete the output of the token, for example because the agent CLI stopped reading or standard output is closed.
    fix: >-
      Restart the agent CLI and try again.
      If a script runs the command, let the command write to standard output, and keep the read end of a pipe open until the command exits.
  - message: "`fresh login is required`"
    cause: >-
      `token` doesn't open a browser, so it can't start a new sign-in, and the saved sign-in can't be renewed: the identity provider rejected it during renewal, the sign-in is missing or expired, or the saved sign-in is damaged or doesn't match the profile.
      `token` also prints this line when the token that it got isn't a valid bearer token.
    fix: "Run `kong-harnesses login --profile PROFILE_NAME`."
  - message: "`credential operation could not complete` or `token operation could not complete`"
    cause: kong-harnesses stopped for a reason that it can't name, such as a first sign-in in the browser that failed.
    fix: >-
      If this is the first sign-in, run `kong-harnesses login --profile PROFILE_NAME` in a terminal.
      If `login` fails, run `kong-harnesses login --profile PROFILE_NAME --diagnostics`, and follow the step in the `Next` field.
      Otherwise, try again later.
      If it keeps failing, run `kong-harnesses doctor --profile PROFILE_NAME`.
{% endtable %}

The lines about the secret store, the session, the profile folder and the callback address depend on the operating system:

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
    cause: The Keychain doesn't trust this kong-harnesses build yet, for example after an upgrade.
    fix: >-
      Run `kong-harnesses login --profile PROFILE_NAME`.
      Each time the Keychain asks whether kong-harnesses can use its sign-in, click **Always Allow**.
  - message: "`profile storage is unavailable, because HOME is not set to an absolute path`"
    cause: "kong-harnesses can't find an absolute path for your user configuration directory, because `HOME` isn't set to an absolute path."
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
    fix: >-
      Use a desktop session with a keyring, such as GNOME Keyring or KWallet.
      In a CI job, use a profile that reads its key from `KONG_HARNESSES_STATIC_KEY`.
  - message: "`this session has no per-user runtime directory (XDG_RUNTIME_DIR)`"
    cause: >-
      The session doesn't set `XDG_RUNTIME_DIR` to an absolute path, for example in a container or a CI job.
      `logout` also prints this line.
    fix: >-
      Create a local directory that your user owns and only your user can open, such as with `install -d -m 0700 RUNTIME_DIR`.
      Then set `XDG_RUNTIME_DIR` to the absolute path of the directory.
  - message: "`profile storage is unavailable, because XDG_CONFIG_HOME is not an absolute path, or it is unset and HOME is not`"
    cause: >-
      kong-harnesses can't find an absolute path for your user configuration directory.
      `XDG_CONFIG_HOME` is set to a relative path, or `XDG_CONFIG_HOME` is unset or empty and `HOME` isn't set to an absolute path.
    fix: >-
      Set `XDG_CONFIG_HOME` to an absolute path, or unset it and set `HOME`.
      Then try again.
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
    cause: The session can't use DPAPI, for example an SSH session that signed in with a key.
    fix: >-
      Use your desktop session, where you set up kong-harnesses.
      An SSH session that signed in with your password can also use DPAPI.
  - message: "`your system password store refused access to your sign-in`"
    cause: The system password store refused access to the sign-in.
    fix: "Run `kong-harnesses login --profile PROFILE_NAME`."
  - message: "`profile storage is unavailable, because AppData is not set to an absolute path`"
    cause: "kong-harnesses can't find an absolute path for your user configuration directory, because `AppData` isn't set to an absolute path."
    fix: "Set `AppData` to your roaming application data folder, then try again."
  - message: "`another program on this computer, such as another developer's sign-in, is using the sign-in callback address, or Windows reserved that port`"
    cause: >-
      Windows reserved the port of the callback address, or another program on this computer uses the port.
      When another program uses the port, follow the fix for the `is using the sign-in callback address` line in [When kong-harnesses can't give an access token](#when-kong-harnesses-can-t-give-an-access-token).
    fix: >-
      To find the port, run `kong-harnesses profile get PROFILE_NAME` and read the `Redirect URI` field.
      `netsh interface ipv4 show excludedportrange protocol=tcp` and `netsh interface ipv6 show excludedportrange protocol=tcp` list the reserved ports.
      If Windows reserved the port, ask your administrator to register a redirect URI with a free port at the identity provider and to give you a new profile with that redirect URI.
      Then import the new profile, activate it, and sign in again.
{% endtable %}
{% endnavtab %}
{% endnavtabs %}

For errors about which profile a command uses, including the lines that start with `selected profile`, see [Profile errors](/kong-harnesses/errors/#profile-errors).

## When the login or logout command fails

When `login` or `logout` can't finish, it prints one line that starts with `Error:`.
An error in the command arguments also prints a line that says how to see the usage.
`login --diagnostics` reports the failure in its own output.
The following table lists the start of the lines after `Error:` that only `login` and `logout` print, and the refusal messages for agent CLIs that sign in through their own plugin:

{% table %}
columns:
  - title: Message
    key: message
  - title: Cause
    key: cause
  - title: What to do
    key: fix
rows:
  - message: "`OpenCode owns authentication`"
    cause: "You ran `login`, `logout`, `credential` or `token` with `--client opencode`."
    fix: "Follow the OpenCode steps in [Sign in to a profile](/kong-harnesses/sign-in/#sign-in-to-a-profile)."
  - message: "`the Kong AI Gateway plugin owns authentication for Hermes`"
    cause: "You ran `login`, `logout`, `credential` or `token` with `--client hermes`."
    fix: "Follow the Hermes Agent steps in [Sign in to a profile](/kong-harnesses/sign-in/#sign-in-to-a-profile)."
  - message: "`login requires an interactive controlling terminal` or `logout asks you to type the profile name, so it needs an interactive controlling terminal`"
    cause: "`login` or `logout` ran without a terminal, for example in a script or a CI job."
    fix: >-
      Run the command in a terminal.
      For `logout`, you can also pass `--auto-approve` to confirm in advance.
      In a CI job, use a profile that reads its key from `KONG_HARNESSES_STATIC_KEY`, set the variable in the job, and don't run `login` for that profile.
  - message: "`login accepts only one mode flag`"
    cause: "`login` got both `--replace` and `--diagnostics`."
    fix: "Run `login` with one of the two flags."
  - message: "`login cannot combine --diagnostics with --no-browser`"
    cause: "`--diagnostics` doesn't print the sign-in URL, so it can't be used with `--no-browser`."
    fix: "Run `login --diagnostics` without `--no-browser`."
  - message: "`no usable login exists`"
    cause: "`login --replace` didn't find a saved sign-in or key to replace."
    fix: "Run `kong-harnesses login --profile PROFILE_NAME`."
  - message: "`local sign-in disabled; server sign-out unconfirmed`"
    cause: >-
      `logout` disabled the sign-in on this computer, but it couldn't confirm that the identity provider revoked all authorizations for the profile.
      For example, the identity provider didn't confirm the revocation, or `logout` found an older copy of the sign-in from an earlier release that it can't read or choose.
    fix: >-
      Run `kong-harnesses status --profile PROFILE_NAME` to check the sign-in on this computer.
      Check the authorization at the identity provider, and revoke it there if it's still active, even if a later `logout` shows `Already signed out`.
      Then run `kong-harnesses logout --profile PROFILE_NAME` again.
  - message: "`server sign-out confirmed; local cleanup incomplete`"
    cause: The identity provider confirmed the revocation, but kong-harnesses couldn't remove everything from this computer, or it couldn't release its lock on the profile after the removal.
    fix: "Run `kong-harnesses logout --profile PROFILE_NAME` again."
  - message: "`local cleanup incomplete; logout did not contact the server`"
    cause: >-
      `logout` didn't contact the identity provider, and it couldn't remove everything from this computer.
      This happens when the profile doesn't have a sign-in on this computer and keys of gateway MCP servers are left, when the profile doesn't name a revocation endpoint, or when the profile uses a key from your administrator.
    fix: "Run `kong-harnesses logout --profile PROFILE_NAME` again."
  - message: "`saved sign-in needs attention and server state is unknown`"
    cause: >-
      The saved sign-in or key can't be used, and `logout` couldn't remove it from this computer.
      `logout` didn't contact the identity provider.
    fix: >-
      Run `kong-harnesses status --profile PROFILE_NAME` to check the sign-in on this computer, then run `kong-harnesses logout --profile PROFILE_NAME` again.
      For a profile that signs in through an identity provider, also check the authorization at the identity provider.
  - message: "`logout cancelled before completion`"
    cause: "`logout` stopped before it finished, for example because you cancelled the confirmation."
    fix: "Run `kong-harnesses logout --profile PROFILE_NAME` again."
  - message: "`logout could not complete`"
    cause: "`logout` stopped for a reason that its message doesn't name."
    fix: "Check the sign-in with `kong-harnesses status --profile PROFILE_NAME`, then run `logout` again."
  - message: "`login result could not be written`, `logout result could not be written`, or `diagnostic report could not be written`"
    cause: >-
      The command couldn't write its output, for example because the terminal closed.
      The command can change the sign-in before its output fails.
    fix: "Run `kong-harnesses status --profile PROFILE_NAME` to check the sign-in on this computer before you run the command again."
  - message: "`login could not complete`"
    cause: "`login` stopped for a reason that its message doesn't name."
    fix: "Run `kong-harnesses login --profile PROFILE_NAME --diagnostics` to find the cause."
  - message: "`login cancelled; no usable login was created`"
    cause: >-
      The sign-in or the confirmation stopped.
      The command can also stop right after it saved the sign-in.
    fix: >-
      Run `kong-harnesses status --profile PROFILE_NAME`.
      Run `kong-harnesses login --profile PROFILE_NAME` again in an interactive terminal if `Login` doesn't show `Ready`, or if the profile uses keys for gateway MCP servers, because `login` asks for those keys after it saves the sign-in.
  - message: "`the sign-in is saved, but a gateway MCP server has no key yet`"
    cause: "`login` saved the sign-in but not the key of a gateway MCP server: you stopped `login`, the prompt timed out, or the text that you entered isn't a valid key."
    fix: "Run `kong-harnesses login --profile PROFILE_NAME` again to add the key."
  - message: "`the sign-in is saved, but the system password store did not save the key of a gateway MCP server`"
    cause: The system password store couldn't read, remove or save the key, for example because it's locked.
    fix: "Unlock the system password store if it's locked, then run `kong-harnesses login --profile PROFILE_NAME`."
{% endtable %}

When `login` can't read the saved key of a gateway MCP server, the line depends on the operating system:

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
    cause: The Keychain doesn't let this kong-harnesses build read the key, for example because you clicked **Allow** and not **Always Allow**.
    fix: >-
      Run `kong-harnesses login --profile PROFILE_NAME` again.
      When the Keychain asks, click **Always Allow**.
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
    cause: The system password store refused to give the key, for example because it's locked.
    fix: "Unlock the system password store, or run `kong-harnesses login --profile PROFILE_NAME` again."
{% endtable %}
{% endnavtab %}
{% endnavtabs %}
