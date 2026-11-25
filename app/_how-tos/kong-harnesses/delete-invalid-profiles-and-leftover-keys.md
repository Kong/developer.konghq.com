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
    Delete an invalid user profile with `kong-harnesses profile delete PROFILE_NAME`, then run `kong-harnesses profile cleanup`.
    Remove any leftover gateway MCP server keys (`PROFILE_NAME.mcp-key.*`) from macOS Keychain, Linux Secret Service, or `%LOCALAPPDATA%\kong-harnesses\vault` on Windows.

related_resources:
  - text: Remove kong-harnesses
    url: /kong-harnesses/remove-kong-harnesses/
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
    - title: An invalid user profile
      content: |
        A user profile that `doctor`, `logout`, `profile get`, or `profile list` reports as invalid or unreadable, and whose message names `kong-harnesses profile delete`.
        If the message names a different fix, follow it instead.
        Keep kong-harnesses installed until you finish these steps.
---

When a user profile is invalid or unreadable, `kong-harnesses logout` can't read it to revoke your sign-in.
Gateway MCP server keys can also stay in your system password store after `profile delete`.
Use these steps to delete an invalid user profile and remove any leftover keys.
Run them in your own user account, in a desktop session that can reach your system password store.

## Delete the invalid profile

1. Delete the profile, replacing `PROFILE_NAME` with the profile name:

   ```sh
   kong-harnesses profile delete PROFILE_NAME
   ```

   Type the profile name when prompted to confirm.
   For an invalid profile, `profile delete` doesn't refuse while an agent CLI uses it, and it removes the saved gateway MCP server keys that it can find.
1. Clean up each agent CLI that used the profile:

   ```sh
   kong-harnesses profile cleanup --client CLIENT_NAME
   ```

   Omit `--client CLIENT_NAME` to clean up every supported agent CLI.
1. If the `Login` field warns that a saved sign-in might remain, import a valid copy of the profile with [`profile import`](/kong-harnesses/profile/import/), run `kong-harnesses logout --profile PROFILE_NAME`, and delete the profile again.

## Delete leftover gateway MCP server keys

Delete leftover gateway MCP server keys when the `Gateway MCP keys` field of `profile delete` names items that might remain.
On macOS, also check each keychain when that field is absent, including after `logout` of a valid profile.

Replace `ITEM_NAME` with a name from the `Gateway MCP keys` field or from the list command in your operating system tab, such as `PROFILE_NAME.mcp-key.SERVER_NAME`.
Profile names can't contain a dot, so `PROFILE_NAME.mcp-key.` matches only the items of that profile.

{% navtabs "delete-gateway-mcp-keys" %}
{% navtab "macOS" %}

Each item is a generic password with the service `io.kong.kong-harnesses.login` and the item name as its account.
kong-harnesses saves items in your default keychain and searches only the keychains that `security list-keychains` prints, so `profile delete` doesn't report a copy in any other keychain.

Repeat these steps for each keychain that `security list-keychains` prints, except `/Library/Keychains/System.keychain`.
Also repeat them for a former default keychain that isn't in that output.
macOS can ask for the keychain password, normally your login password, to allow each deletion.

1. List the keychains in your search list:

   ```sh
   security list-keychains
   ```

1. In a terminal of your desktop session, read one keychain path into a variable:

   ```sh
   IFS= read -r KEYCHAIN_PATH
   ```

   Paste the path without the double quotes that `security list-keychains` prints around it, or the path of a former default keychain that isn't in that output, then press Enter.
   For example: `/Users/USER/Library/Keychains/login.keychain-db`.
1. In the same terminal, unlock the keychain:

   ```sh
   security unlock-keychain "$KEYCHAIN_PATH"
   ```

   Enter the keychain password when asked.
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

   The loop runs until every match is deleted, because `security delete-generic-password` deletes one item at a time.
1. Check that each item is gone, even if `security` reported that the password was deleted:

   ```sh
   security find-generic-password -s io.kong.kong-harnesses.login -a 'ITEM_NAME' "$KEYCHAIN_PATH" >/dev/null
   ```

   The item is gone when the command prints that it couldn't be found in the keychain.
   Any other result means that the item is still there.
   This counts only if the unlock step succeeded, because `security` also prints that message when the keychain is locked.

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
