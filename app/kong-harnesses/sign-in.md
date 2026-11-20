---
title: Sign in with kong-harnesses
description: Sign in to a kong-harnesses profile, check the sign-in, and fix each problem that stops kong-harnesses from giving your agent CLI an access token.

content_type: reference
layout: reference

tools:
  - kong-harnesses

tags:
  - ai
  - authentication
  - cli
  - troubleshooting

breadcrumbs:
  - /kong-harnesses/

related_resources:
  - text: kong-harnesses login
    url: /kong-harnesses/login/
  - text: kong-harnesses doctor
    url: /kong-harnesses/doctor/
  - text: Set up {{ site.claude_code }} with kong-harnesses
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
---

kong-harnesses signs you in to {{ site.ai_gateway }} and gives your agent CLI, such as {{ site.claude_code }}, an access token or a key when the agent CLI asks for one. The profile decides how you sign in: through your company's identity provider in a browser, or with a key from your administrator. kong-harnesses keeps the sign-in or the key in the computer's own secret store: the macOS Keychain, Windows DPAPI, or Secret Service on Linux. A profile for a CI job reads its key from the environment instead. For a profile that signs in through an identity provider, when the agent CLI asks for a token and the saved token has too little time left, kong-harnesses gets a new one from the identity provider without opening the browser.

## Sign in to a profile

Run the [`login`](/kong-harnesses/login/) command with the name of the profile:

```sh
kong-harnesses login --profile PROFILE_NAME
```

Replace `PROFILE_NAME` with the name of your installed profile, here and in each command on this page.

Run `login` in an interactive terminal, not in a script or a CI job. `logout` also needs a terminal when the profile has a saved sign-in, because it then asks you to confirm.

For a profile that signs in through an identity provider, kong-harnesses opens your browser at the sign-in page of the identity provider. The terminal also prints the sign-in URL, so you can open the URL yourself if the browser doesn't open. Open it in a browser on the same computer, because the browser sends the sign-in result to a callback address on this computer. To print the URL without opening a browser, add `--no-browser`.

When the profile already has a usable sign-in, `login` keeps it and asks for and saves any missing keys of the gateway MCP servers that the profile names. After a new sign-in, follow the step in the `Next` field, and restart each agent CLI that uses the profile if it's running.

For a profile that uses a key from your administrator, `login` asks for the key and doesn't show it as you type.

A profile for a CI job reads its key from `KONG_HARNESSES_STATIC_KEY` each time the agent CLI asks for one. kong-harnesses doesn't save this key, and `login` refuses the profile. Set the variable in the environment where the agent CLI starts.

OpenCode and Hermes Agent sign in through their own plugin, so `login`, `logout`, `credential` and `token` refuse `--client opencode` and `--client hermes`. Use the plugin commands for those agent CLIs. For OpenCode, start OpenCode once after activation, so that it installs the plugin. Then run `opencode auth login`, select the provider that has the name of the profile, and restart OpenCode to load the model list. To sign out of OpenCode, run `opencode auth logout`. For Hermes Agent, sign in with `hermes auth add kong-ai-gateway`. To remove all credentials of the `kong-ai-gateway` provider, run `hermes auth logout kong-ai-gateway`. To remove one credential from a pool, run `hermes auth list kong-ai-gateway`, then run `hermes auth remove kong-ai-gateway TARGET` with its index, entry ID or exact label.

You don't have to run `login` before you start {{ site.claude_code }} with a profile that signs in through an identity provider. When {{ site.claude_code }} asks for its first access token and the profile doesn't have a sign-in yet, kong-harnesses opens the browser for you. Run `login` first for a profile that uses a key from your administrator, because only `login` asks for the key. To use your own Claude subscription, run `kong-harnesses login --profile PROFILE_NAME` for your identity at the gateway before you start {{ site.claude_code }}. Then sign in to Claude with `/login` in {{ site.claude_code }}. For a profile that signs in through an identity provider, also run `login` before you first use an agent CLI that gets its token from [`token`](/kong-harnesses/token/), such as the `codex`, `omp` and `pi` clients, because `token` doesn't open a browser.

## Check the sign-in

Show the sign-in of a profile with the [`status`](/kong-harnesses/status/) command, which doesn't use the network:

```sh
kong-harnesses status --profile PROFILE_NAME
```

The `Login` field shows the state of the sign-in:

{% table %}
columns:
  - title: Login
    key: state
  - title: What it means
    key: meaning
rows:
  - state: "`Ready`"
    meaning: "This computer has a saved sign-in or key, or the environment where you run `status` has a key in the right format. `status` doesn't check the sign-in with the identity provider or the key with the gateway."
  - state: "`Not signed in`"
    meaning: "The profile doesn't have a sign-in on this computer. Run [`kong-harnesses login --profile PROFILE_NAME`](/kong-harnesses/login/)."
  - state: "`Sign-in needs attention`"
    meaning: "The saved sign-in can't be used. Run `kong-harnesses login --profile PROFILE_NAME`."
  - state: "`Usable; an interrupted refresh resumes on the next call`"
    meaning: The last renewal stopped before it finished. The sign-in still works, and the next request for an access token resumes the renewal.
  - state: "`KONG_HARNESSES_STATIC_KEY is unset or holds no valid key`"
    meaning: "The profile reads its key from the environment, and `KONG_HARNESSES_STATIC_KEY` isn't set to a valid key. Set `KONG_HARNESSES_STATIC_KEY` to the key from your administrator."
  - state: "`Managed by the client`"
    meaning: "The agent CLI that `status` reports on, such as OpenCode, signs in through its own plugin, so kong-harnesses doesn't keep a sign-in for it. Follow the step in the `Next` field."
{% endtable %}

Without `--profile` or `KONG_HARNESSES_PROFILE`, `status` lists every profile. When the list shows `Unknown` for a profile, run `kong-harnesses status --profile PROFILE_NAME` to find the cause. When `Profile state` shows `Unreadable; reimport it`, [import the profile](/kong-harnesses/profile/import/) again. When it shows `Unreadable; ask your administrator to reinstall it`, the profile is installed for every user, so ask your administrator to install it again.

To check the whole setup, including a request to the gateway, run [`kong-harnesses doctor --profile PROFILE_NAME`](/kong-harnesses/doctor/).

## Sign in again

To start a new sign-in while the current one still works, run [`login`](/kong-harnesses/login/) with `--replace`:

```sh
kong-harnesses login --profile PROFILE_NAME --replace
```

`login --replace` asks you to type the profile name to confirm. It disables the current sign-in on this computer before it starts the new one, so if the new sign-in fails, run `login` again. The identity provider can keep the old authorization active.

For a profile that uses a key from your administrator and already has a saved key, `login --replace` removes the saved key, asks for the new key, and saves it. When the profile doesn't have a saved sign-in or key yet, `login --replace` says that no usable login exists, so run a plain `login`. When the saved sign-in or key is damaged or doesn't match the profile, `login --replace` says that the sign-in needs attention, so also run a plain `login`.

When the saved sign-in is damaged or doesn't match the profile, a plain `login` asks you to type the profile name to confirm. kong-harnesses then removes the saved sign-in from this computer and starts a new sign-in. The identity provider can keep the old authorization active. When the secret store is locked or refuses access, `login` doesn't ask, and prints the line for that problem from the table in [When kong-harnesses can't give an access token](#when-kong-harnesses-can-t-give-an-access-token).

When the last renewal stopped before it finished, a plain `login` starts a new sign-in without a confirmation. If the new sign-in fails, the next request for an access token can still resume the renewal.

## Sign out

Remove the sign-in from this computer with the [`logout`](/kong-harnesses/logout/) command:

```sh
kong-harnesses logout --profile PROFILE_NAME
```

When the profile has a saved sign-in, `logout` asks you to type the profile name to confirm. What it does depends on the profile and the saved sign-in:

- When the profile names a revocation endpoint and the saved sign-in can be used, `logout` revokes the sign-in at the identity provider, then removes it from this computer.
- When `logout` can't confirm that the identity provider revoked all authorizations for the profile, it disables the sign-in on this computer and says that the sign-out at the identity provider is unconfirmed. This happens when the identity provider doesn't confirm the revocation, and when this computer has a sign-in from an earlier release that kong-harnesses can't read. `logout` removes that earlier sign-in without a revocation, so a later `logout` can show `Already signed out` while its authorization is still active. Check the authorization at the identity provider, and revoke it there if it's still active. Then run `logout` again to finish the removal from this computer, or to confirm that the sign-in is gone from it.
- When the profile doesn't name a revocation endpoint, `logout` says that it can't confirm the sign-out at the identity provider. It asks before it removes the sign-in from this computer.
- When the saved sign-in is damaged or doesn't match the profile, `logout` removes it from this computer only.
- When the profile doesn't have a sign-in on this computer, `logout` doesn't ask you to confirm, and shows `Already signed out`. It also removes any keys of gateway MCP servers that are left.
- When `logout` says that the local cleanup is incomplete, or that the saved sign-in needs attention, run `logout` again. The table in [When the login or logout command fails](#when-the-login-or-logout-command-fails) lists each of these lines.

A {{ site.claude_code }} session that already has an access token can use it until the token expires.

For a profile that uses a key from your administrator, `logout` removes the key from this computer only. The key works at the gateway until your administrator revokes it. For a profile for a CI job, `logout` shows `Already signed out`, because kong-harnesses doesn't save the key. On Linux, `logout` first takes a lock on the profile in `XDG_RUNTIME_DIR`, so set that variable in the job before you run `logout`. If this computer still has a saved sign-in or key for the profile, `logout` asks you to confirm and removes it. In a Linux session without Secret Service, `logout` doesn't check for a saved sign-in or key, so to remove one that an earlier setup saved, run `logout` in a desktop session with a keyring. `logout` doesn't remove `KONG_HARNESSES_STATIC_KEY`, and the agent CLI can still use the key while the variable is set. Remove the variable from the job environment yourself.

## When kong-harnesses can't give an access token

When the [`credential`](/kong-harnesses/credential/) command can't give {{ site.claude_code }} an access token, it prints one line that starts with `Error:`, and {{ site.claude_code }} shows that line. The line says what's wrong, and many lines also say what to run. The table lists the start of each line after `Error:`. When the browser doesn't open for a first sign-in, kong-harnesses also prints the sign-in URL. Open the URL in a browser on the same computer while kong-harnesses waits for the sign-in. When kong-harnesses stops waiting, the URL no longer works, so run `kong-harnesses login --profile PROFILE_NAME` to get a new URL.

In a terminal, [`token`](/kong-harnesses/token/), [`status`](/kong-harnesses/status/) and [`login`](/kong-harnesses/login/) print the same line for many of these problems. Every kong-harnesses command prints the `profile storage is unavailable` and `the profiles in FOLDER could not be moved` lines, because kong-harnesses checks the profile folder before the command runs. [`logout`](/kong-harnesses/logout/) prints the same line when the secret store refuses access to the sign-in or doesn't run in the session, when the session has no `XDG_RUNTIME_DIR`, when the saved sign-in needs attention, and when another kong-harnesses command uses the profile.

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
    cause: "The sign-in expired, the identity provider revoked it, or the saved sign-in can't be used. From `logout`, the line can also mean that `logout` couldn't release its lock on the profile."
    fix: "Run `kong-harnesses login --profile PROFILE_NAME`. When `logout` prints this line, run `kong-harnesses logout --profile PROFILE_NAME` again first. If it prints the line again, run `login`, then `logout`."
  - message: "`the last renewal of this sign-in did not finish`"
    cause: A renewal stopped before it finished. The saved sign-in still works.
    fix: "Nothing: the next request resumes the renewal. If requests keep failing, run `kong-harnesses login --profile PROFILE_NAME`. If the new sign-in fails, the old one stays as it was."
  - message: "`the sign-in server cannot be reached`"
    cause: kong-harnesses can't reach the identity provider.
    fix: "Check your network or VPN, or run [`kong-harnesses doctor --profile PROFILE_NAME`](/kong-harnesses/doctor/)."
  - message: "`no browser opened to sign in`"
    cause: kong-harnesses couldn't open a browser for the first sign-in, and no sign-in result arrived at the callback address.
    fix: "Run `kong-harnesses login --profile PROFILE_NAME` in a terminal. The terminal prints the sign-in URL."
  - message: "`another program on this computer, such as another developer's sign-in, is using the sign-in callback address`"
    cause: Another program on this computer uses the callback address of the profile, such as another developer's sign-in on a shared computer.
    fix: "If another sign-in uses the address, wait until it finishes. Otherwise, stop the program that uses the port of the callback address. Then try again. On Windows, the line can also say that Windows reserved the port. `netsh interface ipv4 show excludedportrange protocol=tcp` and `netsh interface ipv6 show excludedportrange protocol=tcp` list the reserved ports. If Windows reserved the port, ask your administrator for a profile with a free callback port. To find the port, run `kong-harnesses profile get PROFILE_NAME` and read the `Redirect URI` field."
  - message: "`another kong-harnesses command, such as a sign-in or a renewal, is using this profile`"
    cause: Another kong-harnesses command uses the profile, such as a sign-in that waits for the browser.
    fix: Try again when the other command finishes.
  - message: "`your Keychain is locked`"
    cause: The macOS Keychain is locked.
    fix: "Run `security unlock-keychain`, then try again."
  - message: "`your Keychain does not yet let this kong-harnesses build read your sign-in`"
    cause: The macOS Keychain doesn't trust this kong-harnesses build yet, for example after an upgrade.
    fix: "Run `kong-harnesses login --profile PROFILE_NAME`. Each time the Keychain asks whether kong-harnesses can use its sign-in, click **Always Allow**."
  - message: "`your system password store is locked`"
    cause: The Linux keyring is locked.
    fix: Unlock the keyring, then try again.
  - message: "`your system password store refused access to your sign-in`"
    cause: The system password store refused access to the sign-in.
    fix: "Run `kong-harnesses login --profile PROFILE_NAME`."
  - message: "`Windows cannot save or read your sign-in in this session`"
    cause: The Windows session can't use DPAPI, for example an SSH session that signed in with a key.
    fix: Use your desktop session, where you set up kong-harnesses. An SSH session that signed in with your password can also use DPAPI.
  - message: "`no Secret Service runs in this session`"
    cause: The Linux session doesn't have a keyring.
    fix: "Use a desktop session with a keyring, such as GNOME Keyring or KWallet. In a CI job, use a profile that reads its key from `KONG_HARNESSES_STATIC_KEY`."
  - message: "`this session has no per-user runtime directory (XDG_RUNTIME_DIR)`"
    cause: "The Linux session doesn't set `XDG_RUNTIME_DIR` to an absolute path, for example in a container or a CI job."
    fix: "Create a local directory that your user owns and only your user can open, such as with `install -d -m 0700 RUNTIME_DIR`. Then set `XDG_RUNTIME_DIR` to the absolute path of the directory."
  - message: "`this profile has no saved key`"
    cause: The profile uses a key from your administrator, and this computer doesn't have the key yet.
    fix: "Run `kong-harnesses login --profile PROFILE_NAME`, and enter the key from your administrator."
  - message: "`profile \"PROFILE_NAME\" reads its key from KONG_HARNESSES_STATIC_KEY`"
    cause: "The profile reads its key from the environment, as in a CI job. From `credential` or `token`, `KONG_HARNESSES_STATIC_KEY` isn't set to a valid key. From `login`, the line says that there is nothing to log in to, because kong-harnesses doesn't save this key."
    fix: "Set `KONG_HARNESSES_STATIC_KEY` to the key from your administrator in the environment where the agent CLI starts. Don't run `login` for this profile."
  - message: "`a proxy is set for the plain-HTTP gateway GATEWAY_URL`"
    cause: "The profile uses an `http://` gateway on this computer, and a proxy variable applies to the gateway host where the agent CLI starts. The proxy could read the access token."
    fix: "Add the gateway host to `NO_PROXY` in your shell, and also to `no_proxy` if it's set. For a gateway at an IPv6 address, add each form that the line names, such as `[::1]:8000,[::1],::1`, because clients read an IPv6 address in `NO_PROXY` differently. For {{ site.claude_code }}, then run `kong-harnesses profile activate PROFILE_NAME --client claude-code` again, so that its settings exclude the gateway from the proxy. Project and managed settings can override these exclusions, and managed settings can stop the activation. Run `kong-harnesses doctor --profile PROFILE_NAME --client claude-code` from the project folder, and follow its proxy steps. Then run `kong-harnesses profile activate PROFILE_NAME --client claude-code` again, and restart {{ site.claude_code }}. For omp and pi, set the same exclusions where the agent CLI starts. Codex, OpenCode and Hermes Agent need an `https://` gateway, because kong-harnesses doesn't set them up for an `http://` gateway. You can also use an `https://` gateway. Then try again."
  - message: "`profile storage is unavailable, because`"
    cause: "kong-harnesses can't find an absolute path for your user configuration directory. The line names the variable: `AppData` on Windows, `HOME` on macOS, or `HOME` and `XDG_CONFIG_HOME` on Linux."
    fix: "On Windows, set `AppData` to your roaming application data folder. On macOS, set `HOME` to your home folder. On Linux, set `XDG_CONFIG_HOME` to an absolute path, or unset it and set `HOME`. Then try again."
  - message: "`the profiles in FOLDER could not be moved to FOLDER`"
    cause: kong-harnesses couldn't move the profiles of an earlier release to their new folder.
    fix: Move the profile folder to the path that the line gives, then run the command again.
  - message: "`profile storage could not be read`"
    cause: kong-harnesses can't open the folder that contains its profiles, or it can't read the profile file.
    fix: "Make sure that your user can open the profile folder and read the profile file, then try again. To check the profiles, run [`kong-harnesses profile list`](/kong-harnesses/profile/list/)."
  - message: "`this profile uses your own Claude subscription`"
    cause: "The profile uses your own Claude subscription. {{ site.claude_code }} sends its own Claude sign-in to the model, so `credential` doesn't give it a token."
    fix: "Sign in to Claude in {{ site.claude_code }} with `/login`. `kong-harnesses login --profile PROFILE_NAME` still signs you in for your identity at the gateway."
  - message: "`credential operation cancelled before access-token output`, `token operation cancelled before access-token output`, or `token operation cancelled before credential use`"
    cause: The request stopped before kong-harnesses wrote the token.
    fix: Try again.
  - message: "`access token output could not be prepared` or `access token output could not be completed`"
    cause: kong-harnesses couldn't prepare or complete the output of the token.
    fix: "Try again. If it keeps failing, run `kong-harnesses doctor --profile PROFILE_NAME`."
  - message: "`fresh login is required`"
    cause: "`token` doesn't open a browser, so it can't start a new sign-in, and the saved sign-in can't be renewed: the identity provider rejected it during renewal, the sign-in is missing or expired, or the saved sign-in is damaged or doesn't match the profile. `token` also prints this line when the token that it got isn't a valid bearer token."
    fix: "Run `kong-harnesses login --profile PROFILE_NAME`."
  - message: "`credential operation could not complete` or `token operation could not complete`"
    cause: kong-harnesses stopped for a reason that it can't name, such as a first sign-in in the browser that failed.
    fix: "If this is the first sign-in, run `kong-harnesses login --profile PROFILE_NAME` in a terminal. If `login` fails, run `kong-harnesses login --profile PROFILE_NAME --diagnostics`, and follow the step in the `Next` field. Otherwise, try again later. If it keeps failing, run `kong-harnesses doctor --profile PROFILE_NAME`."
{% endtable %}

For errors about which profile a command uses, including the lines that start with `selected profile`, see [Profile errors](/kong-harnesses/errors/#profile-errors).

## When the login or logout command fails

When `login` or `logout` can't finish, it prints one line that starts with `Error:`. An error in the command arguments also prints a line that says how to see the usage. `login --diagnostics` reports the failure in its own output. The table lists the start of the lines after `Error:` that only `login` and `logout` print, and the refusal messages for agent CLIs that sign in through their own plugin:

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
    fix: "Run `opencode auth login`, select the provider that has the name of the profile, and restart OpenCode. To sign out, run `opencode auth logout`."
  - message: "`the Kong AI Gateway plugin owns authentication for Hermes`"
    cause: "You ran `login`, `logout`, `credential` or `token` with `--client hermes`."
    fix: "To sign in, run `hermes auth add kong-ai-gateway`. To remove all credentials of the `kong-ai-gateway` provider, run `hermes auth logout kong-ai-gateway`. To remove one credential from a pool, run `hermes auth list kong-ai-gateway`, then run `hermes auth remove kong-ai-gateway TARGET` with its index, entry ID or exact label."
  - message: "`login requires an interactive controlling terminal` or `logout requires an interactive controlling terminal`"
    cause: "`login` or `logout` ran without a terminal, for example in a script or a CI job."
    fix: "Run the command in a terminal. In a CI job, use a profile that reads its key from `KONG_HARNESSES_STATIC_KEY`."
  - message: "`login accepts only one mode flag`"
    cause: "`login` got both `--replace` and `--diagnostics`."
    fix: "Run `login` with one of the two flags."
  - message: "`login cannot combine --diagnostics with --no-browser`"
    cause: "`--diagnostics` doesn't print the sign-in URL, so it can't be used with `--no-browser`."
    fix: "Run `login --diagnostics` without `--no-browser`."
  - message: "`no usable login exists`"
    cause: "`login --replace` found no saved sign-in or key to replace."
    fix: "Run `kong-harnesses login --profile PROFILE_NAME`."
  - message: "`local sign-in disabled; server sign-out unconfirmed`"
    cause: "`logout` disabled the sign-in on this computer, but it couldn't confirm that the identity provider revoked all authorizations for the profile. For example, the identity provider didn't confirm the revocation, or this computer has a sign-in from an earlier release that kong-harnesses can't read."
    fix: "Run `kong-harnesses status --profile PROFILE_NAME` to check the sign-in on this computer. Check the authorization at the identity provider, and revoke it there if it's still active. Then run `kong-harnesses logout --profile PROFILE_NAME` again."
  - message: "`server sign-out confirmed; local cleanup incomplete`"
    cause: The identity provider confirmed the revocation, but kong-harnesses couldn't remove everything from this computer, or it couldn't release its lock on the profile after the removal.
    fix: "Run `kong-harnesses logout --profile PROFILE_NAME` again."
  - message: "`local cleanup incomplete; server sign-out not checked`"
    cause: "`logout` didn't contact the identity provider, and it couldn't remove everything from this computer. This happens when the profile has no sign-in on this computer and keys of gateway MCP servers are left, when the profile doesn't name a revocation endpoint, or when the profile uses a key from your administrator."
    fix: "Run `kong-harnesses logout --profile PROFILE_NAME` again."
  - message: "`saved sign-in needs attention and server state is unknown`"
    cause: "The saved sign-in or key can't be used, and `logout` couldn't remove it from this computer. `logout` didn't contact the identity provider."
    fix: "Run `kong-harnesses status --profile PROFILE_NAME` to check the sign-in on this computer, then run `kong-harnesses logout --profile PROFILE_NAME` again. For a profile that signs in through an identity provider, also check the authorization at the identity provider."
  - message: "`logout cancelled before completion`"
    cause: "`logout` stopped before it finished, for example because you cancelled the confirmation."
    fix: "Run `kong-harnesses logout --profile PROFILE_NAME` again."
  - message: "`logout could not complete`"
    cause: "`logout` stopped for a reason that its message doesn't name."
    fix: "Check the sign-in with `kong-harnesses status --profile PROFILE_NAME`, then run `logout` again."
  - message: "`login result could not be written`, `logout result could not be written`, or `diagnostic report could not be written`"
    cause: The command couldn't write its output, for example because the terminal closed. The command can change the sign-in before its output fails.
    fix: "Run `kong-harnesses status --profile PROFILE_NAME` to check the sign-in on this computer before you run the command again."
  - message: "`login could not complete`"
    cause: "`login` stopped for a reason that its message doesn't name."
    fix: "Run `kong-harnesses login --profile PROFILE_NAME --diagnostics` to find the cause."
  - message: "`your Keychain does not let this kong-harnesses build read the saved key of the gateway MCP server`"
    cause: The macOS Keychain doesn't let this kong-harnesses build read the key, for example because you clicked **Allow** and not **Always Allow**.
    fix: "Run `kong-harnesses login --profile PROFILE_NAME` again. When the Keychain asks, click **Always Allow**."
  - message: "`your system password store did not let kong-harnesses read the saved key of the gateway MCP server`"
    cause: The system password store refused to give the key, for example because it's locked.
    fix: "Unlock the system password store, or run `kong-harnesses login --profile PROFILE_NAME` again."
  - message: "`login cancelled; no usable login was created`"
    cause: The sign-in or the confirmation stopped before kong-harnesses saved a sign-in.
    fix: "Run `kong-harnesses login --profile PROFILE_NAME` again."
  - message: "`the sign-in is saved, but a gateway MCP server has no key yet`"
    cause: "`login` saved the sign-in but not the key of a gateway MCP server: you stopped `login`, the prompt timed out, or the text that you entered isn't a valid key."
    fix: "Run `kong-harnesses login --profile PROFILE_NAME` again to add the key."
  - message: "`the sign-in is saved, but the system password store did not save the key of a gateway MCP server`"
    cause: The system password store couldn't read, remove or save the key, for example because it's locked.
    fix: "Unlock the system password store if it's locked, then run `kong-harnesses login --profile PROFILE_NAME`."
{% endtable %}

## Find out why a sign-in fails

When [`login`](/kong-harnesses/login/) fails and its message doesn't say why, run `login` with `--diagnostics`:

```sh
kong-harnesses login --profile PROFILE_NAME --diagnostics
```

`login --diagnostics` names the part that failed and the reason, such as a token lifetime that the profile doesn't accept, a missing refresh token, or a secret store that isn't available. It never prints the access token or the sign-in URL. When the profile doesn't have a usable sign-in, `login --diagnostics` tries to sign in, so it can ask to remove the saved sign-in and open the browser. When the sign-in is ready, it doesn't send a request, but it still asks for any missing keys of gateway MCP servers. `--diagnostics` can't be used with `--no-browser` or `--replace`.
