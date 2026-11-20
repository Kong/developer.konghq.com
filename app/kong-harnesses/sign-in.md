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

kong-harnesses signs you in to {{ site.ai_gateway }} and gives your agent CLI, such as {{ site.claude_code }}, an access token each time the agent CLI asks for one. The profile decides how you sign in: through your company's identity provider in a browser, or with a key from your administrator. kong-harnesses keeps the sign-in in the computer's own secret store: the macOS Keychain, Windows DPAPI, or Secret Service on Linux. For a profile that signs in through an identity provider, kong-harnesses gets a new access token from the identity provider when the old one expires, without opening the browser.

## Sign in to a profile

Run the [`login`](/kong-harnesses/login/) command with the name of the profile:

```sh
kong-harnesses login --profile <profile>
```

For a profile that signs in through an identity provider, kong-harnesses opens your browser at the sign-in page of the identity provider. The terminal also prints the sign-in URL, so you can open the URL yourself if the browser doesn't open. Open it in a browser on the same computer, because the browser sends the sign-in result to a callback address on this computer. To print the URL without opening a browser, add `--no-browser`.

For a profile that uses a key from your administrator, `login` asks for the key and doesn't show it as you type.

A profile for a CI job reads its key from `KONG_HARNESSES_STATIC_KEY` each time the agent CLI asks for one. kong-harnesses doesn't save this key, and `login` refuses the profile. Set the variable in the environment where the agent CLI starts.

You don't have to run `login` before you start {{ site.claude_code }} with a profile that signs in through an identity provider. When {{ site.claude_code }} asks for its first access token and the profile doesn't have a sign-in yet, kong-harnesses opens the browser for you.

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
    meaning: The sign-in works.
  - state: "`Not signed in`"
    meaning: "The profile doesn't have a sign-in on this computer. Run `kong-harnesses login --profile <profile>`."
  - state: "`Sign-in needs attention`"
    meaning: "The saved sign-in can't be used. Run `kong-harnesses login --profile <profile>`."
  - state: "`Usable; an interrupted refresh resumes on the next call`"
    meaning: The last renewal stopped before it finished. The sign-in still works, and the next request for an access token resumes the renewal.
  - state: "`KONG_HARNESSES_STATIC_KEY is unset or holds no valid key`"
    meaning: "The profile reads its key from the environment, and the variable doesn't hold a valid key. Set `KONG_HARNESSES_STATIC_KEY` to the key from your administrator."
  - state: "`Managed by the client`"
    meaning: "The profile uses your own Claude subscription, and {{ site.claude_code }} keeps the sign-in. Sign in to Claude in {{ site.claude_code }} with `/login`."
{% endtable %}

To check the whole setup, including a request to the gateway, run [`kong-harnesses doctor`](/kong-harnesses/doctor/).

## Sign in again

To start a new sign-in while the current one still works, add `--replace`:

```sh
kong-harnesses login --profile <profile> --replace
```

For a profile that uses a key from your administrator, `login --replace` saves a new key.

When the saved sign-in can't be used, a plain `login` finds the problem and asks you to type the profile name to confirm. kong-harnesses then removes the saved sign-in from this computer and starts a new sign-in. The identity provider can keep the old authorization active.

## Sign out

Remove the sign-in from this computer with the [`logout`](/kong-harnesses/logout/) command:

```sh
kong-harnesses logout --profile <profile>
```

When the profile names a revocation endpoint, `logout` also revokes the sign-in at the identity provider. Otherwise, `logout` says that it can't confirm the sign-out at the identity provider, and asks before it removes the sign-in from this computer. A {{ site.claude_code }} session that already has an access token can use it until the token expires.

For a profile that uses a key from your administrator, `logout` removes the key from this computer only. The key works at the gateway until your administrator revokes it.

## When kong-harnesses can't give an access token

When the [`credential`](/kong-harnesses/credential/) command can't give {{ site.claude_code }} an access token, it prints one line, and {{ site.claude_code }} shows that line. The line says what's wrong and what to run. In a terminal, [`token`](/kong-harnesses/token/), `status` and `login` print the same line for many of these problems.

{% table %}
columns:
  - title: The line starts with
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
    fix: "Check your network or VPN, or run `kong-harnesses doctor --profile <profile>`."
  - message: "`no browser opened to sign in`"
    cause: The profile doesn't have a sign-in yet, and kong-harnesses couldn't open a browser.
    fix: "Run `kong-harnesses login --profile <profile>` in a terminal. The terminal prints the sign-in URL."
  - message: "`another program on this computer, such as another developer's sign-in, is using the sign-in callback address`"
    cause: Another sign-in on this computer uses the callback address of the profile, such as another developer's sign-in on a shared computer.
    fix: Wait until the other sign-in finishes, then try again.
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
    cause: "The Linux session doesn't set `XDG_RUNTIME_DIR`, for example in a container or a CI job."
    fix: "Set `XDG_RUNTIME_DIR` to a new directory that only your user can open."
  - message: "`this profile has no saved key`"
    cause: The profile uses a key from your administrator, and this computer doesn't have the key yet.
    fix: "Run `kong-harnesses login --profile <profile>`, and enter the key from your administrator."
  - message: "`profile \"<profile>\" reads its key from KONG_HARNESSES_STATIC_KEY`"
    cause: "The profile reads its key from the environment, as in a CI job, and `KONG_HARNESSES_STATIC_KEY` isn't set or doesn't hold a valid key."
    fix: "Set `KONG_HARNESSES_STATIC_KEY` to the key from your administrator."
  - message: "`a proxy is set for the plain-HTTP gateway`"
    cause: "The profile uses an `http://` gateway on this computer, and a proxy variable applies to the gateway host where the agent CLI starts. The proxy could read the access token."
    fix: "Add the gateway host to `NO_PROXY` where the agent CLI starts, then try again. For a gateway at `[::1]`, use `http://127.0.0.1` as the gateway address instead, because clients read an IPv6 address in `NO_PROXY` differently."
  - message: "`selected profile does not exist`"
    cause: kong-harnesses doesn't have a profile with this name.
    fix: "Run `kong-harnesses profile list` to see the installed profiles."
  - message: "`selected profile is invalid`"
    cause: The saved profile can't be read.
    fix: Install the profile again from a trusted source.
  - message: "`selected profile uses an unsupported format`"
    cause: The profile uses a format that this kong-harnesses build doesn't support.
    fix: Install the profile again with this kong-harnesses build.
  - message: "`the profile installed for every user can be changed by an account that is not an administrator`"
    cause: kong-harnesses doesn't use a profile for every user that an account without administrator rights can change.
    fix: Ask your administrator to install the profile again.
  - message: "`this profile uses your own Claude subscription`"
    cause: "The profile uses your own Claude subscription, so {{ site.claude_code }} sends its own sign-in, and kong-harnesses doesn't give it a token."
    fix: "Sign in to Claude in {{ site.claude_code }} with `/login`."
  - message: "`credential operation could not complete`"
    cause: kong-harnesses stopped for a reason that it can't name.
    fix: "Try again later. If it keeps failing, run `kong-harnesses doctor --profile <profile>`."
{% endtable %}

## Find out why a sign-in fails

When `login` fails and its message doesn't say why, run `login` with `--diagnostics`:

```sh
kong-harnesses login --profile <profile> --diagnostics
```

`login --diagnostics` names the part that failed and the reason, such as a token lifetime that the profile doesn't accept, a missing refresh token, or a secret store that isn't available. It never prints the access token or the sign-in URL. When the profile doesn't have a usable sign-in, `login --diagnostics` makes one real sign-in attempt, so it can ask to remove the saved sign-in and open the browser. When the sign-in is ready, it doesn't send a request.
