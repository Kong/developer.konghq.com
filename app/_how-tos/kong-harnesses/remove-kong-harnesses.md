---
title: Remove kong-harnesses
description: Sign out of profiles, clean up agent CLI settings, delete installed profiles, and uninstall kong-harnesses on macOS, Linux, and Windows.
content_type: how_to
permalink: /kong-harnesses/remove-kong-harnesses/
breadcrumbs:
  - /kong-harnesses/

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kong-harnesses

tags:
  - cli
  - troubleshooting

automated_tests: false

tldr:
  q: How do I remove kong-harnesses and undo its agent CLI setup?
  a: |
    Run `kong-harnesses logout --profile PROFILE_NAME` for each profile, and sign out through the OpenCode or Hermes Agent plugin if you use either.
    Then run `kong-harnesses profile cleanup` to restore agent CLI settings, and run `kong-harnesses profile delete PROFILE_NAME` to delete each user profile.
    `logout` revokes the sign-in at your identity provider only when the profile supports server sign-out, and removes it locally otherwise.
    For what `logout` revokes, see [Sign out](/kong-harnesses/sign-in/#sign-out).
    Finally, uninstall kong-harnesses with the package manager or installer that installed it.

related_resources:
  - text: kong-harnesses
    url: /kong-harnesses/
  - text: Install kong-harnesses for every user of a computer
    url: /kong-harnesses/install/
  - text: Sign in with kong-harnesses
    url: /kong-harnesses/sign-in/
  - text: kong-harnesses profile cleanup
    url: /kong-harnesses/profile/cleanup/
  - text: kong-harnesses logout
    url: /kong-harnesses/logout/
  - text: kong-harnesses profile delete
    url: /kong-harnesses/profile/delete/

prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: Desktop session with kong-harnesses installed
      content: |
        Keep kong-harnesses installed until you finish signing out, cleaning up agent CLI settings, and deleting profiles.
        Run these steps in your own user account in an interactive desktop session that can reach your system password store.
---

Uninstalling kong-harnesses leaves behind your saved sign-ins, installed profiles, and agent CLI settings.
Follow these steps in order in your own user account before uninstalling kong-harnesses.
If you only want to undo setup or remove a profile while keeping kong-harnesses installed, skip [Uninstall kong-harnesses](#uninstall-kong-harnesses).

## Sign out of each profile

Sign out of each installed profile before cleaning up agent CLI settings or deleting profiles.
[`kong-harnesses logout`](/kong-harnesses/logout/) needs the stored profile to revoke the sign-in at your identity provider, and OpenCode and Hermes Agent need their plugin settings in place to sign out.
Run `kong-harnesses profile list` to see your installed profile names, and replace `PROFILE_NAME` with each profile name.

`profile list` shows both user profiles that you installed and any machine-wide profile (`installed for every user by your administrator`).
For a machine-wide profile deployed with a {{ site.claude_code }} fleet build, sign out before your administrator removes the fleet build so `logout` can still read the profile.

1. Sign out of the profile and remove its saved sign-in and gateway MCP server keys:

   ```sh
   kong-harnesses logout --profile PROFILE_NAME
   ```

   `logout` removes only the sign-in or static key and gateway MCP server keys that kong-harnesses saved for that profile.
   When the profile has a saved sign-in or static key on this computer, `logout` asks you to type the profile name to confirm before removing it along with any saved gateway MCP server keys.
   When the profile doesn't have a saved sign-in or static key on this computer, `logout` removes any remaining gateway MCP server keys without asking you to confirm and prints `Already signed out`.
   `logout` can remove a sign-in locally without revoking it at an identity provider, such as for a static-key profile or a profile without a revocation endpoint.
   For what `logout` revokes across identity provider, static-key, and CI profiles, see [Sign out](/kong-harnesses/sign-in/#sign-out).

   If `profile list` or `logout` reports that a profile is unreadable or invalid, follow the next step in the message:

   * **Needs a newer kong-harnesses (`update kong-harnesses`):** Update kong-harnesses, then run `logout` again.
   * **Unreadable machine-wide profile (`ask your administrator to reinstall it` or `ask your administrator to remove it`):** For an invalid or untrusted machine-wide profile (`ask your administrator to reinstall it`), ask your administrator to reinstall the profile so you can run `logout` before they remove the fleet build.
     For a machine-wide file whose name isn't a profile name (`ask your administrator to remove it`), skip `logout` for that entry and ask your administrator to remove the file.
   * **Invalid user profile (names `kong-harnesses profile delete`):** Skip `logout` for that profile, finish the OpenCode and Hermes Agent sign-outs in the next step, and delete the profile later with [Delete an invalid profile](#delete-an-invalid-profile).
   * **User file whose name isn't a profile name (`no command can use or delete it`):** Skip that entry, because no kong-harnesses command can sign out of it or delete it.

   For details on unreadable profile messages, see [Profile errors](/kong-harnesses/errors/#profile-errors).
   If `logout` fails for another reason, complete the step its message names and run `logout` again.
1. If you use OpenCode or Hermes Agent, remove their credentials through each client's own plugin before running `profile cleanup`.
   OpenCode and Hermes Agent sign in through their own plugins, so `kong-harnesses logout` refuses `--client opencode` and `--client hermes`, and their sign-ins stay active.

   * **OpenCode:** Run `opencode auth logout`, then select the provider named after the profile.
   * **Hermes Agent:** Run `hermes auth logout kong-ai-gateway` to remove all credentials for the `kong-ai-gateway` provider.
     To remove only one credential from a pool instead, run `hermes auth list kong-ai-gateway` to find its entry ID, then run `hermes auth remove kong-ai-gateway ENTRY_ID`.
     Do not pass an index, which changes when an earlier entry is removed, or a label, which Hermes refuses when more than one entry shares it.

   For these plugin commands, see [Sign in to a profile](/kong-harnesses/sign-in/#sign-in-to-a-profile).

## Clean up agent CLI settings

`kong-harnesses setup` and `kong-harnesses profile activate` change the settings of each agent CLI they configure.
[`kong-harnesses profile cleanup`](/kong-harnesses/profile/cleanup/) restores the values those settings contained before and removes the values kong-harnesses added.

`profile cleanup` doesn't take a profile name.
Without `--client`, it works on every supported agent CLI and removes settings that any kong-harnesses profile wrote.
To clean up only one agent CLI, add `--client CLIENT_NAME`, for example `--client claude-code`.

On a computer with a [{{ site.claude_code }} fleet build](/kong-harnesses/remove-a-claude-code-fleet-build/), every developer with a user-level activation still runs `kong-harnesses profile cleanup --client claude-code` before uninstalling, regardless of the build's MCP mode (including an `exclusive` build).
`profile cleanup` works before or after an administrator deletes fleet build files, as long as kong-harnesses is still installed.

1. Preview the changes that `profile cleanup` would make:

   ```sh
   kong-harnesses profile cleanup --dry-run
   ```

1. Remove the settings that kong-harnesses added:

   ```sh
   kong-harnesses profile cleanup
   ```

`profile cleanup` changes only the values that kong-harnesses still owns and leaves any values you edited after activation intact.
Its output names each setting or group of settings that holds your edits for each agent CLI that finished cleanup.
Without `--client`, it still lists those edits even when cleanup fails for another agent CLI.

If `profile cleanup` can't tell which values it owns, complete the steps its message names, such as inspecting the settings and removing leftover values manually.
If `profile cleanup` changes settings but can't finish cleanup for one or more agent CLIs (with or without `--client`), complete the step its message names, then run `profile cleanup` again.
For what each exit code means, see [Exit codes](/kong-harnesses/errors/#exit-codes).

`profile cleanup` doesn't sign you out and doesn't delete any profile.

## Delete each profile

Delete each user profile after `logout` and `profile cleanup` finish.
[`kong-harnesses profile delete`](/kong-harnesses/profile/delete/) comes last because the profile holds what `logout` needs to revoke the sign-in.
For a valid profile, `profile delete` refuses while you're still signed in or while any agent CLI still uses the profile.

`profile delete` removes only user profiles that you installed.
For a machine-wide profile (`installed for every user by your administrator` in `profile list`), `profile delete` refuses before asking you to confirm and without removing any saved keys.
Only an administrator can remove a machine-wide profile by following [Remove a {{ site.claude_code }} fleet build](/kong-harnesses/remove-a-claude-code-fleet-build/).

1. Delete the stored profile document:

   ```sh
   kong-harnesses profile delete PROFILE_NAME
   ```

1. Type the profile name when prompted to confirm.

If an agent CLI still uses the profile, `profile delete` refuses and names the next step, such as running `kong-harnesses profile cleanup --client CLIENT_NAME` (or asking your administrator to remove a fleet build if managed settings run the profile).
Complete that step, then run `profile delete` again.

### Delete an invalid profile

If `doctor`, `logout`, `profile get`, or `profile list` reports that a user profile is invalid or unreadable and names `kong-harnesses profile delete`, kong-harnesses can't read it, so you can't run `logout` first.
This procedure applies only to an invalid user profile.
If an unreadable profile needs a newer kong-harnesses release, update kong-harnesses and run `logout` again.
If an unreadable profile is machine-wide, ask your administrator to reinstall it so you can run `logout` before they remove the fleet build, or to remove the file if its name isn't a profile name.

1. Delete the invalid user profile without running `logout`:

   ```sh
   kong-harnesses profile delete PROFILE_NAME
   ```

   For an invalid user profile, `profile delete` doesn't refuse while an agent CLI uses the profile or while a saved sign-in remains.
   After you confirm, it removes the profile and the saved gateway MCP server keys for each server the invalid document lists.
   If it can't remove a key or can't read the server list from the document, the `Gateway MCP keys` field of its output names the items (`PROFILE_NAME.mcp-key.SERVER_NAME` or `PROFILE_NAME.mcp-key.*`) to delete from your system password store.
   When a saved sign-in might remain, `profile delete` warns about it before asking you to confirm and again in the `Login` field of its output.
1. Type the profile name when prompted to confirm.
1. If you use OpenCode or Hermes Agent and haven't signed out through their plugins yet, sign out using [Sign out of each profile](#sign-out-of-each-profile) before running `profile cleanup`.
1. Clean up each agent CLI that still uses the deleted profile, if you haven't already run [Clean up agent CLI settings](#clean-up-agent-cli-settings):

   ```sh
   kong-harnesses profile cleanup --client CLIENT_NAME
   ```

   Omit `--client CLIENT_NAME` to clean up every supported agent CLI.
1. If the `Login` field reports that a saved sign-in might remain, import a valid copy of the profile again, run `kong-harnesses logout --profile PROFILE_NAME`, and then run `kong-harnesses profile delete PROFILE_NAME`.
1. If the `Gateway MCP keys` field lists items that might remain, delete each named item from your system password store.
   Replace `ITEM_NAME` with a name from the output, such as `PROFILE_NAME.mcp-key.SERVER_NAME`.
   Profile names can't contain a dot, so `PROFILE_NAME.mcp-key.` matches only the items of that profile.

{% navtabs "delete-gateway-mcp-keys" %}
{% navtab "macOS" %}

Each item is a password in your default keychain, normally the login keychain, with the service `io.kong.kong-harnesses.login` and the item name as its account.
macOS can ask for the keychain password, normally your login password, to allow each deletion.
If your default keychain changed after you set up kong-harnesses, add the path of the keychain that was the default then, for example `~/Library/Keychains/login.keychain-db`, at the end of each `security` command, including `security unlock-keychain`.
If you don't know which keychain that was, do these steps once for each keychain that `security list-keychains` prints, with its path.

1. In a terminal of your desktop session, unlock the keychain:

   ```sh
   security unlock-keychain
   ```

   Enter the keychain password when `security` asks for it.
1. If the `Gateway MCP keys` field names `PROFILE_NAME.mcp-key.*`, list the item names of that profile:

   ```sh
   security dump-keychain | awk '
     function check() { if (svce == "\"io.kong.kong-harnesses.login\"" && index(acct, "\"PROFILE_NAME.mcp-key.") == 1) print substr(acct, 2, length(acct) - 2) }
     /^keychain: / { check(); acct = ""; svce = "" }
     /^    "acct"<blob>=/ { acct = substr($0, index($0, "=") + 1) }
     /^    "svce"<blob>=/ { svce = substr($0, index($0, "=") + 1) }
     END { check() }'
   ```

   The command prints only item names, not their values.
   Use each name that it prints as `ITEM_NAME` in the next step.
1. Delete each named item:

   ```sh
   while security delete-generic-password -s io.kong.kong-harnesses.login -a 'ITEM_NAME' >/dev/null; do :; done
   ```

   `security delete-generic-password` deletes only the first item that matches, so the loop runs it until no item is left.

1. Check that each item is gone, even if `security` reported that the password has been deleted:

   ```sh
   security find-generic-password -s io.kong.kong-harnesses.login -a 'ITEM_NAME' >/dev/null
   ```

   The command must report that the item couldn't be found in the keychain.
   This result counts only after the unlock step succeeded, because `security` also prints it when the keychain stays locked.
   Any other message, or no message, means that the item is still there.

{% endnavtab %}
{% navtab "Linux" %}

Each item is a Secret Service item with the attribute `application` set to `io.kong.kong-harnesses` and the attribute `profile` set to the item name.

{:.warning}
> Always pass the `profile` attribute to `secret-tool clear`.
> Without it, the command deletes every item that kong-harnesses saved in an unlocked keyring, including your sign-ins.

1. If the `Gateway MCP keys` field names `PROFILE_NAME.mcp-key.*`, list the item names of that profile:

   ```sh
   { secret-tool search --all --unlock application io.kong.kong-harnesses >/dev/null || echo "secret-tool: exit code $?"; } 2>&1 \
     | sed -n -e 's/^attribute\.profile = \(PROFILE_NAME\.mcp-key\.\)/\1/p' -e '/^secret-tool: /p'
   ```

   If your desktop asks you to unlock the keyring, unlock it.
   The command prints only item names, not their values, and a `secret-tool:` line when `secret-tool` fails or is missing.
   Use each name that it prints as `ITEM_NAME` in the next step.
1. Delete each named item while the keyring is unlocked, because `secret-tool clear` removes only items in an unlocked keyring:

   ```sh
   secret-tool clear application io.kong.kong-harnesses profile 'ITEM_NAME'
   ```

1. Check that each item is gone:

   ```sh
   { secret-tool search --all --unlock application io.kong.kong-harnesses >/dev/null || echo "secret-tool: exit code $?"; } 2>&1 \
     | sed -n -e 's/^attribute\.profile = \(PROFILE_NAME\.mcp-key\.\)/\1/p' -e '/^secret-tool: /p'
   ```

   If your desktop asks you to unlock the keyring, unlock it.
   The item is gone only when the command prints neither its name nor a `secret-tool:` line.
   If you cancelled the unlock, unlock the keyring and run the check again.

{% endnavtab %}
{% navtab "Windows" %}

Each item is a file named `ITEM_NAME.login.dpapi` in the `%LOCALAPPDATA%\kong-harnesses\vault` folder.

1. If the `Gateway MCP keys` field names `PROFILE_NAME.mcp-key.*`, delete every item of that profile in PowerShell:

   ```powershell
   Get-ChildItem -LiteralPath "$env:LOCALAPPDATA\kong-harnesses\vault" -Filter 'PROFILE_NAME.mcp-key.*.login.dpapi' | Remove-Item
   ```

1. Delete each other named item:

   ```powershell
   Remove-Item -LiteralPath "$env:LOCALAPPDATA\kong-harnesses\vault\ITEM_NAME.login.dpapi"
   ```

   If PowerShell reports that the path doesn't exist, the item is already gone.

{% endnavtab %}
{% endnavtabs %}

## Uninstall kong-harnesses

Uninstall kong-harnesses using the method that matches how you installed it on your computer.

{% navtabs "uninstall-kong-harnesses" %}
{% navtab "macOS" %}

If you installed kong-harnesses with Homebrew, uninstall the formula:

```sh
brew uninstall kong-harnesses
```

If you or an administrator installed kong-harnesses for every user with the `.pkg` installer, follow [Remove from macOS](/kong-harnesses/install/#remove-from-macos).

{% endnavtab %}
{% navtab "Linux" %}

Uninstall kong-harnesses with the package manager that installed it:

* **Homebrew:**

  ```sh
  brew uninstall kong-harnesses
  ```

* **Ubuntu (`.deb`):**

  ```sh
  sudo apt remove kong-harnesses
  ```

* **Red Hat Enterprise Linux (`.rpm`):**

  ```sh
  sudo dnf remove kong-harnesses
  ```

If an administrator manages the system-wide package on a shared computer, see [Remove from Linux](/kong-harnesses/install/#remove-from-linux).

{% endnavtab %}
{% navtab "Windows" %}

Uninstall the Windows installer with one of the following methods:

* Remove **Kong Harnesses** in **Settings** > **Apps** > **Installed apps**.
* Open PowerShell as an administrator and run Windows Installer with the `.msi` file that installed it, replacing `MSI_PATH` with its full path:

  ```powershell
  msiexec /x "MSI_PATH"
  ```

For silent removal or devices managed with Microsoft Intune, see [Remove from Windows](/kong-harnesses/install/#remove-from-windows).

{% endnavtab %}
{% endnavtabs %}

## Validate

Confirm that kong-harnesses and its settings are removed.

If you uninstalled kong-harnesses, open a new terminal so `PATH` changes take effect and verify that `kong-harnesses` isn't found:

{% navtabs "validate-remove-kong-harnesses" %}
{% navtab "macOS and Linux" %}

```sh
command -v kong-harnesses
```

The command prints nothing and exits with a non-zero status.

{% endnavtab %}
{% navtab "Windows" %}

```powershell
Get-Command kong-harnesses
```

PowerShell reports that `kong-harnesses` isn't recognized.

{% endnavtab %}
{% endnavtabs %}

If you kept kong-harnesses installed and only removed a profile or agent CLI settings, confirm the remaining state:

1. Check installed profiles to confirm each deleted user profile is gone:

   ```sh
   kong-harnesses profile list
   ```

   Use `profile list` rather than `status` to verify deletion, because `KONG_HARNESSES_PROFILE` limits `status` to one profile.
1. Check remaining profiles and agent CLI settings (without `KONG_HARNESSES_PROFILE` set):

   ```sh
   kong-harnesses status
   ```

   Cleaned agent CLIs don't show active kong-harnesses settings.
