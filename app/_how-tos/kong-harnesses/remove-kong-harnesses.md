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
    Run `kong-harnesses logout --profile PROFILE_NAME` for each profile{% comment %}, and sign out through the OpenCode or Hermes Agent plugin if you use either{% endcomment %}.
    Then run `kong-harnesses profile cleanup` to restore agent CLI settings, and run `kong-harnesses profile delete PROFILE_NAME` to delete each user profile.
    Finally, uninstall kong-harnesses with the package manager or installer that installed it.

related_resources:
  - text: Delete invalid profiles and leftover gateway MCP server keys
    url: /kong-harnesses/delete-invalid-profiles-and-leftover-keys/
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
Follow these steps in order, in your own user account, before you uninstall kong-harnesses.

## Sign out of each profile

Sign out of each installed profile before you clean up agent CLI settings or delete profiles, because `logout` needs the stored profile to revoke the sign-in.
Run `kong-harnesses profile list` to see your installed profile names, and replace `PROFILE_NAME` with each name.

A profile marked `installed for every user by your administrator` is machine-wide.
Sign out of it before your administrator removes the {{ site.claude_code }} [fleet build](/kong-harnesses/remove-a-claude-code-fleet-build/), so that `logout` can still read the profile.

1. Sign out of the profile and remove its saved sign-in and gateway MCP server keys:

   ```sh
   kong-harnesses logout --profile PROFILE_NAME
   ```

   When the profile has a saved sign-in or static key on this computer, `logout` asks you to type the profile name to confirm.
   For what `logout` revokes at the identity provider, see [Sign out](/kong-harnesses/sign-in/#sign-out).
{%- comment %}
1. If you use OpenCode or Hermes Agent, sign out through each plugin before you run `profile cleanup`, because they sign in through their own plugins and `kong-harnesses logout` doesn't sign out of them:

   * **OpenCode:** Run `opencode auth logout`, then select the provider named after the profile.
   * **Hermes Agent:** Run `hermes auth logout kong-ai-gateway` to remove all credentials for the `kong-ai-gateway` provider.
     To remove one credential, run `hermes auth list kong-ai-gateway` to find its entry ID, then run `hermes auth remove kong-ai-gateway ENTRY_ID`.
     Don't use an index or a label in place of `ENTRY_ID`, because an index changes when an earlier entry is removed, and more than one entry can share a label.

   For the plugin commands, see [Sign in to a profile](/kong-harnesses/sign-in/#sign-in-to-a-profile).
{% endcomment %}

If `logout` fails, complete the step that its message names, then run `logout` again.
For an invalid user profile or gateway MCP server keys that stay after `logout`, follow [Delete invalid profiles and leftover gateway MCP server keys](/kong-harnesses/delete-invalid-profiles-and-leftover-keys/).
For other unreadable profiles, see [Profile errors](/kong-harnesses/errors/#profile-errors).

## Clean up agent CLI settings

`kong-harnesses setup` and `kong-harnesses profile activate` change the settings of each agent CLI that they configure.
[`kong-harnesses profile cleanup`](/kong-harnesses/profile/cleanup/) restores the values that those settings held before, and removes the values that kong-harnesses added.
`profile cleanup` doesn't take a profile name.

Without `--client`, `profile cleanup` works on every supported agent CLI.
To clean up one agent CLI, add `--client CLIENT_NAME`, for example `--client claude-code`.
On a computer with a [{{ site.claude_code }} fleet build](/kong-harnesses/remove-a-claude-code-fleet-build/), run `profile cleanup` if you also activated a profile at the user level, because managed fleet settings don't clear user-level settings.

1. Preview the changes that `profile cleanup` would make:

   ```sh
   kong-harnesses profile cleanup --dry-run
   ```

1. Remove the settings that kong-harnesses added:

   ```sh
   kong-harnesses profile cleanup
   ```

`profile cleanup` changes only the values that kong-harnesses owns, and leaves the values that you edited after activation.
Its output names the settings that hold your edits.

If `profile cleanup` can't finish, complete the step that its message names, then run `profile cleanup` again.
For what each exit code means, see [Exit codes](/kong-harnesses/errors/#exit-codes).

`profile cleanup` doesn't sign you out and doesn't delete any profile.

## Delete each profile

Delete each user profile after `logout` and `profile cleanup` finish, because the profile holds what `logout` needs to revoke the sign-in.
[`kong-harnesses profile delete`](/kong-harnesses/profile/delete/) removes only user profiles that you installed.
Only an administrator can remove a machine-wide profile, by following [Remove a {{ site.claude_code }} fleet build](/kong-harnesses/remove-a-claude-code-fleet-build/).

1. Delete the stored profile document:

   ```sh
   kong-harnesses profile delete PROFILE_NAME
   ```

1. Type the profile name when prompted to confirm.

If an agent CLI still uses the profile, `profile delete` names the next step, such as running `kong-harnesses profile cleanup --client CLIENT_NAME`.
When managed settings run the profile, ask your administrator to remove the fleet build.
Complete the step, then run `profile delete` again.

If a user profile is invalid or `profile delete` reports leftover gateway MCP server keys, follow [Delete invalid profiles and leftover gateway MCP server keys](/kong-harnesses/delete-invalid-profiles-and-leftover-keys/).

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

Open a new terminal so `PATH` changes take effect, and confirm that `kong-harnesses` isn't found:

{% navtabs "validate-remove-kong-harnesses" %}
{% navtab "macOS" %}

```sh
command -v kong-harnesses
```

The command prints nothing and exits with a non-zero status.

{% endnavtab %}
{% navtab "Linux" %}

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

{:.info}
> If an administrator uninstalls kong-harnesses for you, or you kept it installed, run `kong-harnesses profile list` to confirm each deleted user profile is gone.
> Then run `kong-harnesses status` with `KONG_HARNESSES_PROFILE` unset to confirm that cleaned agent CLIs don't show active kong-harnesses settings.
