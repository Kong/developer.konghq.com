---
title: Sign in with kong-harnesses
description: Sign in to a kong-harnesses profile, check or replace the sign-in, sign out, and diagnose sign-in failures.

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
  - text: Sign-in errors in kong-harnesses
    url: /kong-harnesses/sign-in/errors/
  - text: kong-harnesses login
    url: /kong-harnesses/login/
  - text: kong-harnesses doctor
    url: /kong-harnesses/doctor/
  - text: Set up {{ site.claude_code }} with kong-harnesses
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
---

kong-harnesses signs you in to {{ site.ai_gateway }} and gives your agent CLI, such as {{ site.claude_code }}, an access token or a key when the agent CLI asks for one.
The profile decides how you sign in: through your company's identity provider in a browser, or with a key from your administrator.
kong-harnesses keeps the sign-in or the key in the computer's own secret store.
A profile for a CI job reads its key from the environment instead.
For a profile that signs in through an identity provider, when the agent CLI asks for a token and the saved token has too little time left, kong-harnesses gets a new one from the identity provider without opening the browser.

The secret store depends on the operating system:

{% table %}
columns:
  - title: Operating system
    key: os
  - title: Secret store
    key: store
rows:
  - os: macOS
    store: Keychain
  - os: Linux
    store: Secret Service, such as GNOME Keyring or KWallet
  - os: Windows
    store: DPAPI
{% endtable %}

## Sign in to a profile

Run the [`login`](/kong-harnesses/login/) command with the name of the profile:

```sh
kong-harnesses login --profile PROFILE_NAME
```

Replace `PROFILE_NAME` with the name of your installed profile, here and in each command on this page.

Run `login` in an interactive terminal, not in a script or a CI job.
`logout` also needs a terminal when the profile has a saved sign-in, because it asks you to confirm unless you pass `--auto-approve`.

For a profile that signs in through an identity provider, kong-harnesses opens your browser at the sign-in page of the identity provider.
The terminal also prints the sign-in URL, so you can open the URL yourself if the browser doesn't open.
Open it in a browser on the same computer, because the browser sends the sign-in result to a callback address on this computer.
To print the URL without opening a browser, add `--no-browser`.

When the profile already has a usable sign-in, `login` keeps it and asks for and saves any missing keys of the gateway MCP servers that the profile names.
After a new sign-in, follow the step in the `Next` field, and restart each agent CLI that uses the profile if it's running.

For a profile that uses a key from your administrator, `login` asks for the key and doesn't show it as you type.

A profile for a CI job reads its key from `KONG_HARNESSES_STATIC_KEY` each time the agent CLI asks for one.
kong-harnesses doesn't save this key, and `login` refuses the profile.
Set the variable in the environment where the agent CLI starts.

OpenCode and Hermes Agent sign in through their own plugin, so `login`, `logout`, `credential` and `token` refuse `--client opencode` and `--client hermes`.
Use the plugin commands for those agent CLIs.
For OpenCode, start OpenCode once after activation, so that it installs the plugin.
Then sign in with `opencode auth login PROFILE_NAME` in OpenCode 2, or with `opencode auth login --provider PROFILE_NAME` in OpenCode 1, and restart OpenCode to load the model list.
If the sign-in fails with `Integration not found` or `Unknown provider`, OpenCode couldn't install the plugin.
Run `kong-harnesses doctor --profile PROFILE_NAME --client opencode`.
If the report says that the profile doesn't configure OpenCode, run `kong-harnesses profile get PROFILE_NAME` to see the agent CLIs that the profile sets up.
If you made the profile with [`kong-harnesses profile create`](/kong-harnesses/profile/create/), create it again.
Otherwise, ask your administrator for a profile that sets up OpenCode, and [import it](/kong-harnesses/profile/import/).
Then run `kong-harnesses profile activate PROFILE_NAME --client opencode`, so that the OpenCode configuration names the plugin.
If the report shows the `npm` and `plugin` checks, follow their steps.
Then start OpenCode and sign in again.
To sign out of OpenCode, run `opencode auth logout`.
For Hermes Agent, sign in with `hermes auth add kong-ai-gateway`, then restart Hermes Agent.
To remove all credentials of the `kong-ai-gateway` provider, run `hermes auth logout kong-ai-gateway`.
To remove one credential from a pool, run `hermes auth list kong-ai-gateway`, then run `hermes auth remove kong-ai-gateway TARGET` with the entry ID of the credential as `TARGET`.
Don't use an index, because the index changes when an entry above it is removed, and don't use a label, because more than one credential can have the same label.

You don't have to run `login` before you start {{ site.claude_code }} with a profile that signs in through an identity provider.
When {{ site.claude_code }} asks for its first access token and the profile doesn't have a sign-in yet, kong-harnesses opens the browser for you.
Run `login` first for a profile that uses a key from your administrator, because only `login` asks for the key.
To use your own Claude subscription, run `kong-harnesses login --profile PROFILE_NAME` for your identity at the gateway before you start {{ site.claude_code }}.
Then sign in to Claude with `/login` in {{ site.claude_code }}.
For a profile that signs in through an identity provider, also run `login` before you first use an agent CLI that gets its token from [`token`](/kong-harnesses/token/), such as the `codex`, `omp` and `pi` clients, because `token` doesn't open a browser.

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
    meaning: >-
      This computer has a saved sign-in or key, or the environment where you run `status` has a key in the right format.
      `status` doesn't check the sign-in with the identity provider or the key with the gateway.
  - state: "`Not signed in`"
    meaning: >-
      The profile doesn't have a sign-in on this computer.
      Run [`kong-harnesses login --profile PROFILE_NAME`](/kong-harnesses/login/).
  - state: "`Sign-in needs attention`"
    meaning: >-
      The saved sign-in can't be used.
      Run `kong-harnesses login --profile PROFILE_NAME`.
  - state: "`Usable; an interrupted refresh resumes on the next call`"
    meaning: >-
      The last renewal stopped before it finished.
      The sign-in still works, and the next request for an access token resumes the renewal.
  - state: "`KONG_HARNESSES_STATIC_KEY is unset or holds no valid key`"
    meaning: >-
      The profile reads its key from the environment, and `KONG_HARNESSES_STATIC_KEY` isn't set to a valid key.
      Set `KONG_HARNESSES_STATIC_KEY` to the key from your administrator.
  - state: "`Managed by the client`"
    meaning: >-
      The agent CLI that `status` reports on, such as OpenCode, signs in through its own plugin, so kong-harnesses doesn't keep a sign-in for it.
      Follow the step in the `Next` field.
{% endtable %}

Without `--profile` or `KONG_HARNESSES_PROFILE`, `status` lists every profile.
When the list shows `Unknown` for a profile, run `kong-harnesses status --profile PROFILE_NAME` to find the cause.
When `Profile state` starts with `Unreadable`, the field names the next step for the cause, such as a delete and a new import of the profile, an update of kong-harnesses, or a new install by your administrator.
For more about each cause, see [Profile errors](/kong-harnesses/errors/#profile-errors).

To check the whole setup, including a request to the gateway, run [`kong-harnesses doctor --profile PROFILE_NAME`](/kong-harnesses/doctor/).

## Sign in again

To start a new sign-in while the current one still works, run [`login`](/kong-harnesses/login/) with `--replace`:

```sh
kong-harnesses login --profile PROFILE_NAME --replace
```

`login --replace` asks you to type the profile name to confirm.
It disables the current sign-in on this computer before it starts the new one, so if the new sign-in fails, run `login` again.
The identity provider can keep the old authorization active.

For a profile that uses a key from your administrator and already has a saved key, `login --replace` removes the saved key, asks for the new key, and saves it.
When the profile doesn't have a saved sign-in or key yet, `login --replace` says that no usable login exists, so run a plain `login`.
When the saved sign-in or key is damaged or doesn't match the profile, `login --replace` says that the sign-in needs attention, so also run a plain `login`.

When the saved sign-in is damaged or doesn't match the profile, a plain `login` asks you to type the profile name to confirm.
kong-harnesses then removes the saved sign-in from this computer and starts a new sign-in.
The identity provider can keep the old authorization active.
When the secret store is locked, refuses access or doesn't run in the session, `login` doesn't ask, and prints the line for that problem from [When kong-harnesses can't give an access token](/kong-harnesses/sign-in/errors/#when-kong-harnesses-can-t-give-an-access-token).

When the last renewal stopped before it finished, a plain `login` starts a new sign-in without a confirmation.
If the new sign-in fails, the next request for an access token can still resume the renewal.

## Sign out

Remove the sign-in from this computer with the [`logout`](/kong-harnesses/logout/) command:

```sh
kong-harnesses logout --profile PROFILE_NAME
```

When the profile has a saved sign-in, `logout` asks you to type the profile name to confirm.
What it does depends on the profile and the saved sign-in:

- When the profile names a revocation endpoint and the saved sign-in can be used, `logout` disables the current sign-in on this computer before it asks the identity provider to revoke it.
  After the identity provider confirms the revocation, `logout` removes the sign-in from this computer.
- When `logout` reports that server sign-out is unconfirmed, check and revoke the authorization at the identity provider, then run `logout` again.
- When the profile doesn't name a revocation endpoint, `logout` says that it can't confirm the sign-out at the identity provider.
  It asks before it removes the sign-in from this computer.
- When the saved sign-in is damaged or doesn't match the profile, `logout` removes it from this computer only.
- When the profile doesn't have a sign-in on this computer, `logout` doesn't ask you to confirm, and shows `Already signed out`.
  It also removes any keys of gateway MCP servers that are left.
- When `logout` says that the local cleanup is incomplete, or that the saved sign-in needs attention, run `logout` again.

For these and other `logout` failure messages, see [When the login or logout command fails](/kong-harnesses/sign-in/errors/#when-the-login-or-logout-command-fails).

Each time `logout` removes the sign-in or the key from this computer, it also removes the saved keys of gateway MCP servers for the profile.

A {{ site.claude_code }} session that already has an access token can use it until the token expires.

For a profile that uses a key from your administrator, `logout` removes the key from this computer only.
The key works at the gateway until your administrator revokes it.

For a profile for a CI job, kong-harnesses doesn't save the key.
`logout` doesn't remove `KONG_HARNESSES_STATIC_KEY`, and the agent CLI can still use the key while the variable is set.
Remove the variable from the job environment yourself.
If this computer still has a saved sign-in or key for that profile name and the session has access to the secret store, `logout` asks you to confirm and removes it from this computer.
What `logout` does in the job depends on the operating system:

{% navtabs "ci-job-logout" %}
{% navtab "macOS and Windows" %}
`logout` shows `Already signed out` when this computer doesn't have a saved sign-in or key for that profile name.
{% endnavtab %}
{% navtab "Linux" %}
Set `XDG_RUNTIME_DIR` in the job first, or `logout` fails its profile lock.
`logout` shows `Already signed out` when this computer doesn't have a saved sign-in or key for that profile name, or in a session without Secret Service.
In a session without Secret Service, `logout` doesn't remove a sign-in or key that an earlier setup saved, so run `logout` in a desktop session with a keyring to remove it.
{% endnavtab %}
{% endnavtabs %}

## Find out why a sign-in fails

When [`login`](/kong-harnesses/login/) fails and its message doesn't say why, run `login` with `--diagnostics`:

```sh
kong-harnesses login --profile PROFILE_NAME --diagnostics
```

`login --diagnostics` names the part that failed and the reason, such as a token lifetime that the profile doesn't accept, a missing refresh token, or a secret store that isn't available.
It never prints the access token or the sign-in URL.
When the profile doesn't have a usable sign-in, `login --diagnostics` tries to sign in, so it can ask to remove the saved sign-in and open the browser.
When the sign-in is ready, it doesn't send a request, but it still asks for any missing keys of gateway MCP servers.
`--diagnostics` can't be used with `--no-browser` or `--replace`.

For each sign-in, token, `login`, and `logout` error message and its fix, see [Sign-in errors in kong-harnesses](/kong-harnesses/sign-in/errors/).
