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

kong-harnesses signs you in to {{ site.ai_gateway }} and gives your agent CLI, such as {{ site.claude_code }}, an access token or a key when the agent CLI asks for one. The profile decides how you sign in: through your company's identity provider in a browser, or with a key from your administrator. kong-harnesses keeps the sign-in or the key in the computer's own secret store: the macOS Keychain, Windows DPAPI, or Secret Service on Linux. A profile for a CI job reads its key from the environment instead. For a profile that signs in through an identity provider, kong-harnesses gets a new access token from the identity provider before the old one expires, without opening the browser.

## Sign in to a profile

Run the [`login`](/kong-harnesses/login/) command with the name of the profile:

```sh
kong-harnesses login --profile <profile>
```

`login` and `logout` need a terminal, because they can ask you to type the profile name to confirm.

For a profile that signs in through an identity provider, kong-harnesses opens your browser at the sign-in page of the identity provider. The terminal also prints the sign-in URL, so you can open the URL yourself if the browser doesn't open. Open it in a browser on the same computer, because the browser sends the sign-in result to a callback address on this computer. To print the URL without opening a browser, add `--no-browser`.

When the profile already has a usable sign-in, `login` keeps it, and asks for and saves any missing keys of the gateway MCP servers that the profile names. After a new sign-in, follow the step in the `Next` field, and restart each agent CLI that uses the profile if it's running.

For a profile that uses a key from your administrator, `login` asks for the key and doesn't show it as you type.

A profile for a CI job reads its key from `KONG_HARNESSES_STATIC_KEY` each time the agent CLI asks for one. kong-harnesses doesn't save this key, and `login` refuses the profile. Set the variable in the environment where the agent CLI starts.

OpenCode and Hermes Agent sign in through their own plugin, so `login`, `logout`, `credential` and `token` refuse them. For OpenCode, run `opencode auth login` and `opencode auth logout`. For Hermes Agent, run `hermes auth add kong-ai-gateway`.

You don't have to run `login` before you start {{ site.claude_code }} with a profile that signs in through an identity provider. When {{ site.claude_code }} asks for its first access token and the profile doesn't have a sign-in yet, kong-harnesses opens the browser for you. Run `login` first for a profile that uses your own Claude subscription, and for an agent CLI that gets its token from [`token`](/kong-harnesses/token/), such as the `codex`, `omp` and `pi` clients, because `token` doesn't open a browser.

## Check the sign-in

Show the sign-in of a profile with the [`status`](/kong-harnesses/status/) command, which doesn't use the network:

```sh
kong-harnesses status --profile <profile>
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
    meaning: "This computer has a saved sign-in, or the environment where you run `status` has a key in the right format. `status` doesn't check the sign-in with the identity provider or the key with the gateway."
  - state: "`Not signed in`"
    meaning: "The profile doesn't have a sign-in on this computer. Run [`kong-harnesses login --profile <profile>`](/kong-harnesses/login/)."
  - state: "`Sign-in needs attention`"
    meaning: "The saved sign-in can't be used. Run `kong-harnesses login --profile <profile>`."
  - state: "`Usable; an interrupted refresh resumes on the next call`"
    meaning: The last renewal stopped before it finished. The sign-in still works, and the next request for an access token resumes the renewal.
  - state: "`KONG_HARNESSES_STATIC_KEY is unset or holds no valid key`"
    meaning: "The profile reads its key from the environment, and `KONG_HARNESSES_STATIC_KEY` isn't set to a valid key. Set `KONG_HARNESSES_STATIC_KEY` to the key from your administrator."
  - state: "`Managed by the client`"
    meaning: "The agent CLI that `status` reports on, such as OpenCode, signs in through its own plugin, so kong-harnesses doesn't keep a sign-in for it. Follow the step in the `Next` field."
{% endtable %}

Without `--profile` or `KONG_HARNESSES_PROFILE`, `status` lists every profile. When the list shows `Unknown` for a profile, run `kong-harnesses status --profile <profile>` to find the cause. When `Profile state` shows `Unreadable`, import the profile again. For a profile that your administrator installed for every user, ask your administrator to install it again.

To check the whole setup, including a request to the gateway, run [`kong-harnesses doctor`](/kong-harnesses/doctor/).

## Sign in again

To start a new sign-in while the current one still works, run [`login`](/kong-harnesses/login/) with `--replace`:

```sh
kong-harnesses login --profile <profile> --replace
```

`login --replace` asks you to type the profile name to confirm. It disables the current sign-in on this computer before it starts the new one, so if the new sign-in fails, run `login` again. The identity provider can keep the old authorization active.

For a profile that uses a key from your administrator and already has a saved key, `login --replace` saves a new key. When the profile doesn't have a saved sign-in or key yet, `login --replace` says that no usable login exists, so run a plain `login`.

When the saved sign-in can't be used, a plain `login` asks you to type the profile name to confirm. kong-harnesses then removes the saved sign-in from this computer and starts a new sign-in. The identity provider can keep the old authorization active.

When the last renewal stopped before it finished, a plain `login` starts a new sign-in without a confirmation. If the new sign-in fails, the next request for an access token can still resume the renewal.

## Sign out

Remove the sign-in from this computer with the [`logout`](/kong-harnesses/logout/) command:

```sh
kong-harnesses logout --profile <profile>
```

`logout` asks you to type the profile name to confirm. When the profile names a revocation endpoint and the saved sign-in can be used, `logout` also revokes the sign-in at the identity provider. If the identity provider doesn't confirm the revocation, `logout` disables the sign-in on this computer and says that the sign-out at the identity provider is unconfirmed. Check the authorization at the identity provider, then run `logout` again to finish the removal from this computer, or to confirm that the sign-in is gone from it. If `logout` says that the local cleanup is incomplete, or that the saved sign-in needs attention, run `logout` again. When the saved sign-in can't be used, `logout` removes it from this computer only. When the profile doesn't have a sign-in on this computer, `logout` shows `Already signed out` and removes any keys of gateway MCP servers that are left. When the profile doesn't name a revocation endpoint, `logout` says that it can't confirm the sign-out at the identity provider, and asks before it removes the sign-in from this computer. A {{ site.claude_code }} session that already has an access token can use it until the token expires.

For a profile that uses a key from your administrator, `logout` removes the key from this computer only. The key works at the gateway until your administrator revokes it. For a profile for a CI job, `logout` shows `Already signed out`, because kong-harnesses doesn't save the key. Remove `KONG_HARNESSES_STATIC_KEY` from the job environment yourself.

## When kong-harnesses can't give an access token

When the [`credential`](/kong-harnesses/credential/) command can't give {{ site.claude_code }} an access token, it prints one line that starts with `Error:`, and {{ site.claude_code }} shows that line. The line says what's wrong, and many lines also say what to run. The table lists the start of each line after `Error:`. When the browser doesn't open for a first sign-in, kong-harnesses also prints the sign-in URL. Open the URL in a browser on the same computer. In a terminal, [`token`](/kong-harnesses/token/), [`status`](/kong-harnesses/status/) and [`login`](/kong-harnesses/login/) print the same line for many of these problems.

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
    cause: The sign-in expired, the identity provider revoked it, or the saved sign-in can't be used.
    fix: "Run `kong-harnesses login --profile <profile>`."
  - message: "`the last renewal of this sign-in did not finish`"
    cause: A renewal stopped before it finished. The saved sign-in still works.
    fix: "Nothing: the next request resumes the renewal. If requests keep failing, run `kong-harnesses login --profile <profile>`. If the new sign-in fails, the old one stays as it was."
  - message: "`the sign-in server cannot be reached`"
    cause: kong-harnesses can't reach the identity provider.
    fix: "Check your network or VPN, or run [`kong-harnesses doctor --profile <profile>`](/kong-harnesses/doctor/)."
  - message: "`no browser opened to sign in`"
    cause: kong-harnesses couldn't open a browser for the first sign-in, and no sign-in result arrived at the callback address.
    fix: "Run `kong-harnesses login --profile <profile>` in a terminal. The terminal prints the sign-in URL."
  - message: "`another program on this computer, such as another developer's sign-in, is using the sign-in callback address`"
    cause: Another program on this computer uses the callback address of the profile, such as another developer's sign-in on a shared computer.
    fix: If another sign-in uses the address, wait until it finishes. Otherwise, stop the program that uses the port of the callback address. Then try again.
  - message: "`another kong-harnesses command, such as a sign-in or a renewal, is using this profile`"
    cause: Another kong-harnesses command uses the profile, such as a sign-in that waits for the browser.
    fix: Try again when the other command finishes.
  - message: "`your Keychain is locked`"
    cause: The macOS Keychain is locked.
    fix: "Run `security unlock-keychain`, then try again."
  - message: "`your Keychain does not yet let this kong-harnesses build read your sign-in`"
    cause: The macOS Keychain doesn't trust this kong-harnesses build yet, for example after an upgrade.
    fix: "Run `kong-harnesses login --profile <profile>`. Each time the Keychain asks whether kong-harnesses can use its sign-in, click **Always Allow**."
  - message: "`your system password store is locked`"
    cause: The Linux keyring is locked.
    fix: Unlock the keyring, then try again.
  - message: "`your system password store refused access to your sign-in`"
    cause: The system password store refused access to the sign-in.
    fix: "Run `kong-harnesses login --profile <profile>`."
  - message: "`Windows cannot save or read your sign-in in this session`"
    cause: The Windows session can't use DPAPI, for example an SSH session that signed in with a key.
    fix: Use your desktop session, or an SSH session that signed in with your password.
  - message: "`no Secret Service runs in this session`"
    cause: The Linux session doesn't have a keyring.
    fix: "Use a desktop session with a keyring, such as GNOME Keyring or KWallet. In a CI job, use a profile that reads its key from `KONG_HARNESSES_STATIC_KEY`."
  - message: "`this session has no per-user runtime directory (XDG_RUNTIME_DIR)`"
    cause: "The Linux session doesn't set `XDG_RUNTIME_DIR` to an absolute path, for example in a container or a CI job."
    fix: "Set `XDG_RUNTIME_DIR` to the absolute path of a new local directory that only your user can open."
  - message: "`this profile has no saved key`"
    cause: The profile uses a key from your administrator, and this computer doesn't have the key yet.
    fix: "Run `kong-harnesses login --profile <profile>`, and enter the key from your administrator."
  - message: "`profile \"<profile>\" reads its key from KONG_HARNESSES_STATIC_KEY`"
    cause: "The profile reads its key from the environment, as in a CI job. From `credential` or `token`, `KONG_HARNESSES_STATIC_KEY` isn't set to a valid key. From `login`, the line says that there is nothing to log in to, because kong-harnesses doesn't save this key."
    fix: "Set `KONG_HARNESSES_STATIC_KEY` to the key from your administrator in the environment where the agent CLI starts. Don't run `login` for this profile."
  - message: "`a proxy is set for the plain-HTTP gateway <gateway>`"
    cause: "The profile uses an `http://` gateway on this computer, and a proxy variable applies to the gateway host where the agent CLI starts. The proxy could read the access token."
    fix: "For {{ site.claude_code }}, run `kong-harnesses profile activate <profile>` again, so that its settings exclude the gateway from the proxy. For another agent CLI, add the gateway host to `NO_PROXY` where the agent CLI starts, and also to `no_proxy` if it's set. For a gateway at an IPv6 address, add each form that the line names, such as `[::1]:8000,[::1],::1`, because clients read an IPv6 address in `NO_PROXY` differently. You can also use an `https://` gateway. Then try again."
  - message: "`credential requires a profile` or `token requires a profile`"
    cause: The command didn't get a profile name.
    fix: "Name the profile with `--profile <profile>` or with `KONG_HARNESSES_PROFILE`."
  - message: "`credential accepts one profile`, `token accepts one profile`, or a line that says that the profile name after `--profile` is invalid"
    cause: The command got more than one profile, or a value that can't be a profile name.
    fix: "Give one installed profile with `--profile <profile>`."
  - message: "`KONG_HARNESSES_PROFILE holds an invalid profile name`"
    cause: "`KONG_HARNESSES_PROFILE` is set to a value that can't be a profile name."
    fix: "Set `KONG_HARNESSES_PROFILE` to the name of an installed profile, or name the profile with `--profile <profile>`."
  - message: "`profile storage is unavailable`"
    cause: "kong-harnesses can't find your user configuration directory: `HOME` isn't set, or on Linux `XDG_CONFIG_HOME` is a relative path. It also prints this line when it can't move the profiles of an earlier release to their new folder."
    fix: "Set `HOME`, and set `XDG_CONFIG_HOME` to an absolute path or unset it, then try again."
  - message: "`profile storage could not be read`"
    cause: kong-harnesses can't read the folder that contains its profiles.
    fix: "Make sure that your user can read the folder, then run [`kong-harnesses profile list`](/kong-harnesses/profile/list/)."
  - message: "`this profile uses your own Claude subscription`"
    cause: "The profile uses your own Claude subscription. {{ site.claude_code }} sends its own Claude sign-in to the model, so `credential` doesn't give it a token."
    fix: "Sign in to Claude in {{ site.claude_code }} with `/login`. `kong-harnesses login --profile <profile>` still signs you in for your identity at the gateway."
  - message: "`credential operation cancelled before access-token output` or `token operation cancelled before credential use`"
    cause: The request stopped before kong-harnesses wrote the token.
    fix: Try again.
  - message: "`access token output could not be prepared` or `access token output could not be completed`"
    cause: kong-harnesses couldn't prepare or complete the output of the token.
    fix: Start the agent CLI again.
  - message: "`fresh login is required`"
    cause: "`token` doesn't open a browser, so it can't start a new sign-in, and the saved sign-in can't be renewed: the identity provider rejected it during renewal, or the sign-in is missing or expired. `token` also prints this line when the token that it got isn't a valid bearer token."
    fix: "Run `kong-harnesses login --profile <profile>`."
  - message: "`credential operation could not complete` or `token operation could not complete`"
    cause: kong-harnesses stopped for a reason that it can't name.
    fix: "Try again later. If it keeps failing, run `kong-harnesses doctor --profile <profile>`."
{% endtable %}

For the lines that start with `selected profile`, and for `the profile installed for every user can be changed by an account that is not an administrator`, see [Profile errors](/kong-harnesses/errors/#profile-errors).

## When the login command fails

When `login` can't finish, it prints one line that starts with `Error:`. The table lists the start of each line after `Error:` that only `login` prints, and the lines that refuse an agent CLI that signs in through its own plugin:

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
    fix: "Run `opencode auth login` or `opencode auth logout`."
  - message: "`the Kong AI Gateway plugin owns authentication for Hermes`"
    cause: "You ran `login`, `logout`, `credential` or `token` with `--client hermes`."
    fix: "Run `hermes auth add kong-ai-gateway`."
  - message: "`login requires an interactive controlling terminal`"
    cause: "`login` ran without a terminal, for example in a script or a CI job."
    fix: "Run `login` in a terminal. In a CI job, use a profile that reads its key from `KONG_HARNESSES_STATIC_KEY`."
  - message: "`no usable login exists`"
    cause: "`login --replace` found no saved sign-in or key to replace."
    fix: "Run `kong-harnesses login --profile <profile>`."
  - message: "`a usable login already exists`"
    cause: The profile already has a sign-in that works.
    fix: "To sign in with another account, run `kong-harnesses login --profile <profile> --replace`."
  - message: "`login cancelled; no usable login was created`"
    cause: The sign-in or the confirmation stopped before kong-harnesses saved a sign-in.
    fix: "Run `kong-harnesses login --profile <profile>` again."
  - message: "`the sign-in is saved, but a gateway MCP server has no key yet`"
    cause: You stopped `login` before you entered the key of a gateway MCP server.
    fix: "Run `kong-harnesses login --profile <profile>` again to add the key."
  - message: "`the sign-in is saved, but the system password store did not save the key of a gateway MCP server`"
    cause: The system password store didn't save the key, for example because it's locked.
    fix: "Unlock the system password store if it's locked, then run `kong-harnesses login --profile <profile>`."
{% endtable %}

## Find out why a sign-in fails

When [`login`](/kong-harnesses/login/) fails and its message doesn't say why, run `login` with `--diagnostics`:

```sh
kong-harnesses login --profile <profile> --diagnostics
```

`login --diagnostics` names the part that failed and the reason, such as a token lifetime that the profile doesn't accept, a missing refresh token, or a secret store that isn't available. It never prints the access token or the sign-in URL. When the profile doesn't have a usable sign-in, `login --diagnostics` tries to sign in, so it can ask to remove the saved sign-in and open the browser. When the sign-in is ready, it doesn't send a request, but it still asks for any missing keys of gateway MCP servers. `--diagnostics` can't be used with `--no-browser` or `--replace`.
