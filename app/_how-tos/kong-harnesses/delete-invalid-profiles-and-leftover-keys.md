---
title: Delete invalid profiles and leftover gateway MCP server keys
description: Delete an invalid kong-harnesses user profile and remove leftover gateway MCP server keys from macOS Keychain, Linux Secret Service, or Windows DPAPI.
content_type: how_to
permalink: /kong-harnesses/delete-invalid-profiles-and-leftover-keys/
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
  q: How do I delete an invalid kong-harnesses user profile or leftover gateway MCP server keys?
  a: |
    Delete an invalid user profile with `kong-harnesses profile delete PROFILE_NAME`, then {% comment %}sign out of OpenCode or Hermes Agent if needed and {% endcomment %}run `kong-harnesses profile cleanup`.
    If the `Login` field warns that a saved sign-in might remain, import a valid copy of the profile, run `kong-harnesses logout --profile PROFILE_NAME`, and delete it again.
    Remove any leftover gateway MCP server keys (`PROFILE_NAME.mcp-key.*`) from macOS Keychain, Linux Secret Service, or `%LOCALAPPDATA%\kong-harnesses\vault` on Windows.

related_resources:
  - text: Remove kong-harnesses
    url: /kong-harnesses/remove-kong-harnesses/
  - text: Profile errors
    url: /kong-harnesses/errors/#profile-errors
  - text: kong-harnesses profile delete
    url: /kong-harnesses/profile/delete/
  - text: kong-harnesses profile cleanup
    url: /kong-harnesses/profile/cleanup/
  - text: kong-harnesses logout
    url: /kong-harnesses/logout/

prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: Desktop session with kong-harnesses installed
      content: |
        Keep kong-harnesses installed while you delete invalid profiles and clean up agent CLI settings.
        Run these steps in your own user account in an interactive desktop session that can reach your system password store.
---

When a user profile is invalid or unreadable, `kong-harnesses logout` can't read it to revoke your sign-in.
Gateway MCP server keys can also stay in your system password store after `profile delete` or `logout`.
Use these steps to delete an invalid user profile and remove any leftover gateway MCP server keys.

## Delete an invalid profile

Delete an invalid user profile when `doctor`, `logout`, `profile get`, or `profile list` reports that the profile is invalid or unreadable and names `kong-harnesses profile delete`.
For other unreadable profiles, follow the next step in the error message:

* **Needs a newer kong-harnesses (`update kong-harnesses`):** Update kong-harnesses, then follow [Sign out of each profile](/kong-harnesses/remove-kong-harnesses/#sign-out-of-each-profile) and [Delete each profile](/kong-harnesses/remove-kong-harnesses/#delete-each-profile).
* **Unreadable machine-wide profile (`ask your administrator to reinstall it` or `ask your administrator to remove it`):** For an invalid or untrusted machine-wide profile, ask your administrator to reinstall it so you can run `logout` before they remove the fleet build.
  For a machine-wide file whose name isn't a profile name, ask your administrator to remove the file.
* **User file whose name isn't a profile name (`no command can use or delete it`):** Skip that entry, because no kong-harnesses command can sign out of it or delete it.

For details on unreadable profile messages, see [Profile errors](/kong-harnesses/errors/#profile-errors).

1. Delete the invalid user profile without running `logout`, replacing `PROFILE_NAME` with the profile name:

   ```sh
   kong-harnesses profile delete PROFILE_NAME
   ```

   For an invalid user profile, `profile delete` doesn't refuse while an agent CLI uses the profile or while a saved sign-in remains.
   After you confirm, it removes the profile and the saved gateway MCP server keys for each server that the invalid document lists.
   If `profile delete` can't remove a key or can't read the server list from the document, the `Gateway MCP keys` field lists the items (`PROFILE_NAME.mcp-key.SERVER_NAME` or `PROFILE_NAME.mcp-key.*`) to delete from your system password store.
   When a saved sign-in might remain, `profile delete` warns you before asking you to confirm and again in the `Login` field.
1. Type the profile name when prompted to confirm.
{%- comment %}
1. If you use OpenCode or Hermes Agent and haven't signed out through their plugins yet, sign out using [Sign out of each profile](/kong-harnesses/remove-kong-harnesses/#sign-out-of-each-profile) before running `profile cleanup`.
{% endcomment %}
1. Clean up each agent CLI that still uses the deleted profile:

   ```sh
   kong-harnesses profile cleanup --client CLIENT_NAME
   ```

   Omit `--client CLIENT_NAME` to clean up every supported agent CLI.

If the `Login` field reports that a saved sign-in might remain, revoke and remove it before continuing:

1. Import a valid copy of the profile using [`kong-harnesses profile import`](/kong-harnesses/profile/import/), replacing `PROFILE_SOURCE` with the profile file path or URL:

   ```sh
   kong-harnesses profile import PROFILE_SOURCE
   ```

1. Sign out of the profile:

   ```sh
   kong-harnesses logout --profile PROFILE_NAME
   ```

1. Delete the profile:

   ```sh
   kong-harnesses profile delete PROFILE_NAME
   ```

If the `Gateway MCP keys` field lists items that might remain, continue to [Delete leftover gateway MCP server keys](#delete-leftover-gateway-mcp-server-keys).

## Delete leftover gateway MCP server keys

Delete leftover gateway MCP server keys when the `Gateway MCP keys` field of `profile delete` names items that might remain.
On macOS, also check each keychain when that field is absent, including after `logout` of a valid profile.

Replace `ITEM_NAME` with a name from the `Gateway MCP keys` field or from the list command in your operating system tab, such as `PROFILE_NAME.mcp-key.SERVER_NAME`.
Profile names can't contain a dot, so `PROFILE_NAME.mcp-key.` matches only the items of that profile.

{% navtabs "delete-gateway-mcp-keys" %}
{% navtab "macOS" %}

Each item is a generic password with the service `io.kong.kong-harnesses.login` and the item name as its account.
kong-harnesses saves items in your default keychain (normally the login keychain) and searches only the keychains that `security list-keychains` prints.

A later save updates the matching item in that search list, or creates a new item in your default keychain when none matches.
If more than one item matches, the save fails without changes.
As a result, a copy in a keychain outside `security list-keychains` stays behind, and `profile delete` doesn't report it in the `Gateway MCP keys` field.

Repeat these steps once for each keychain that `security list-keychains` prints, skipping `/Library/Keychains/System.keychain` because kong-harnesses doesn't save items there.
If a keychain was your default at any time after you set up kong-harnesses and isn't in `security list-keychains`, repeat these steps for its path too, even when the `Gateway MCP keys` field is absent.
macOS can ask for the keychain password, normally your login password, to allow each deletion.

1. List the keychains in your search list:

   ```sh
   security list-keychains
   ```

1. In a terminal of your desktop session, read one keychain path into a variable:

   ```sh
   IFS= read -r KEYCHAIN_PATH
   ```

   Paste a path from `security list-keychains`, or the path of a former default keychain that isn't in that output, then press Enter.
   For example: `/Users/USER/Library/Keychains/login.keychain-db`.
   Don't paste the spaces and double quotes that `security list-keychains` prints around the path.
   Reading into a variable preserves the path exactly, even when it holds a space, single quote, or `$`.
1. In the same terminal, unlock the keychain:

   ```sh
   security unlock-keychain "$KEYCHAIN_PATH"
   ```

   Enter the keychain password when `security` asks for it.
1. List the item names of that profile in the keychain, whatever the `Gateway MCP keys` field shows:

   ```sh
   security dump-keychain "$KEYCHAIN_PATH" | awk '
     function check() { if (svce == "\"io.kong.kong-harnesses.login\"" && index(acct, "\"PROFILE_NAME.mcp-key.") == 1) print substr(acct, 2, length(acct) - 2) }
     /^keychain: / { check(); acct = ""; svce = "" }
     /^    "acct"<blob>=/ { acct = substr($0, index($0, "=") + 1) }
     /^    "svce"<blob>=/ { svce = substr($0, index($0, "=") + 1) }
     END { check() }'
   ```

   The command prints only item names, not their values.
   Use each printed name as `ITEM_NAME` in the next step.
1. Delete each named item:

   ```sh
   while security delete-generic-password -s io.kong.kong-harnesses.login -a 'ITEM_NAME' "$KEYCHAIN_PATH" >/dev/null; do :; done
   ```

   `security delete-generic-password` deletes only the first matching item, so the loop runs until every match is deleted.
1. Check that each item is gone, even if `security` reported that the password was deleted:

   ```sh
   security find-generic-password -s io.kong.kong-harnesses.login -a 'ITEM_NAME' "$KEYCHAIN_PATH" >/dev/null
   ```

   The command prints a message stating that the item couldn't be found in the keychain.
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
   The command prints only item names, not their values, and prints a `secret-tool:` line when `secret-tool` fails, is missing, or leaves an item locked.
   Use each printed name as `ITEM_NAME` in the next step.
1. Delete each named item while the keyring is unlocked, because `secret-tool clear` removes only items in an unlocked keyring:

   ```sh
   secret-tool clear application io.kong.kong-harnesses profile 'ITEM_NAME'
   ```

1. Check that each item is gone:

   ```sh
   { secret-tool search --all --unlock application io.kong.kong-harnesses profile 'ITEM_NAME' >/dev/null || echo "secret-tool: exit code $?"; } 2>&1 \
     | sed -n -e 's/^attribute\.profile = //p' -e '/^secret-tool: /p'
   ```

   If your desktop asks you to unlock the keyring, unlock it.
   The item is gone only when the command prints neither its name nor a `secret-tool:` line.
   If you canceled the unlock, unlock the keyring and run the check again.

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
1. Check that every matching file for that profile is gone:

   ```powershell
   Get-ChildItem -LiteralPath "$env:LOCALAPPDATA\kong-harnesses\vault" -Filter 'PROFILE_NAME.mcp-key.*.login.dpapi'
   ```

   The command prints nothing when every matching item is removed.

{% endnavtab %}
{% endnavtabs %}

## Validate

After verifying key deletion in your operating system tab, confirm that the invalid profile and its agent CLI settings are removed.

1. Confirm that the deleted user profile doesn't appear in your installed profiles:

   {% validation custom-command %}
   command: kong-harnesses profile list
   expected:
     return_code: 0
   render_output: false
   indent: 3
   {% endvalidation %}

   Use `profile list` rather than `status` to verify deletion, because `KONG_HARNESSES_PROFILE` limits `status` to one profile.
1. Check your remaining profiles and agent CLI settings (with `KONG_HARNESSES_PROFILE` unset):

   ```sh
   kong-harnesses status
   ```

   The output doesn't list the deleted profile or show active kong-harnesses settings for cleaned agent CLIs.
