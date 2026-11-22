---
title: Remove kong-harnesses
description: Clean up agent CLI settings, sign out of profiles, delete installed profiles, and uninstall kong-harnesses on macOS, Linux, and Windows.
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
    Run `kong-harnesses profile cleanup` to restore agent CLI settings, run `kong-harnesses logout --profile PROFILE_NAME` to revoke and remove each saved sign-in, and run `kong-harnesses profile delete PROFILE_NAME` to delete each profile.
    Then uninstall kong-harnesses with Homebrew, `apt`, `dnf`, or Windows Installer.

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
        Keep kong-harnesses installed until you finish cleaning up agent CLI settings, signing out, and deleting profiles.
        Run these steps in your own user account in an interactive desktop session that can reach your system secret store (macOS Keychain, Windows DPAPI, or Secret Service on Linux).
---

Uninstalling kong-harnesses leaves behind your saved sign-ins, installed profiles, and agent CLI settings.
Follow these steps in order in your own user account before uninstalling kong-harnesses.
If you only want to undo setup or remove a profile while keeping kong-harnesses installed, skip [Uninstall kong-harnesses](#uninstall-kong-harnesses).

## Clean up agent CLI settings

`kong-harnesses setup` and `kong-harnesses profile activate` change the settings of each agent CLI they configure.
[`kong-harnesses profile cleanup`](/kong-harnesses/profile/cleanup/) restores the values those settings contained before and removes the values kong-harnesses added.

`profile cleanup` doesn't take a profile name.
Without `--client`, it works on every supported agent CLI and removes settings that any kong-harnesses profile wrote.
To clean up only one agent CLI, add `--client CLIENT_NAME`, for example `--client claude-code`.

On a computer with a {{ site.claude_code }} fleet build, every developer with a user-level activation still runs `kong-harnesses profile cleanup --client claude-code` before uninstalling, regardless of the build's MCP mode (including an `exclusive` build).
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

If `profile cleanup` can't tell which values it owns, it exits with `2`, or with `4` when it already changed another agent CLI.
Complete the steps its message names, such as inspecting the settings and removing leftover values manually.
If `profile cleanup` changes settings but can't finish cleanup for one or more agent CLIs, it exits with `4` (also with `--client`).
Complete the step its message names, then run `profile cleanup` again.

`profile cleanup` doesn't sign you out and doesn't delete any profile.

## Sign out of each profile

Sign out of each installed profile before deleting it, because [`kong-harnesses logout`](/kong-harnesses/logout/) needs the stored profile to revoke the sign-in at your identity provider.
Run `kong-harnesses profile list` if you need to check your installed profile names, and replace `PROFILE_NAME` with each profile name.

1. Sign out of the profile and remove its saved sign-in and gateway MCP server keys:

   ```sh
   kong-harnesses logout --profile PROFILE_NAME
   ```

   `logout` removes only the sign-in and gateway MCP server keys that kong-harnesses saved for that profile.
   When the profile has a saved sign-in or key on this computer, `logout` asks you to type the profile name to confirm.
   When only gateway MCP server keys remain, `logout` removes them without asking.
   If `logout` fails, complete the step its message names and run `logout` again.
   For what `logout` revokes across identity provider, static-key, and CI profiles, see [Sign out](/kong-harnesses/sign-in/#sign-out).
1. If you use OpenCode or Hermes Agent, remove their credentials through each client's own plugin.
   OpenCode and Hermes Agent sign in through their own plugins, so `kong-harnesses logout` refuses `--client opencode` and `--client hermes`, and their sign-ins stay active.

   * **OpenCode:** Run `opencode auth logout`, then select the provider named after the profile.
   * **Hermes Agent:** Run `hermes auth list kong-ai-gateway` to find each credential's entry ID, then remove each entry with `hermes auth remove kong-ai-gateway ENTRY_ID`.
     Do not pass an index, which changes when an earlier entry is removed, or a label, which Hermes refuses when more than one entry shares it.

   For these plugin commands, see [Sign in to a profile](/kong-harnesses/sign-in/#sign-in-to-a-profile).

## Delete each profile

Delete each profile after `profile cleanup` and `logout` finish.
[`kong-harnesses profile delete`](/kong-harnesses/profile/delete/) comes last because the profile holds what `logout` needs to revoke the sign-in.
For a valid profile, `profile delete` refuses while you're still signed in or while any agent CLI still uses the profile.

1. Delete the stored profile document:

   ```sh
   kong-harnesses profile delete PROFILE_NAME
   ```

1. Type the profile name when prompted to confirm.

If an agent CLI still uses the profile, `profile delete` refuses and names the next step, such as running `kong-harnesses profile cleanup --client CLIENT_NAME` (or asking your administrator to remove a fleet build if managed settings run the profile).
Complete that step, then run `profile delete` again.

### Delete an invalid profile

If `doctor`, `logout`, `profile get`, or `profile list` reports that a profile is invalid, kong-harnesses can't read it, so you can't sign out first.

1. Delete the invalid profile without running `logout`:

   ```sh
   kong-harnesses profile delete PROFILE_NAME
   ```

   For an invalid profile, `profile delete` doesn't refuse while an agent CLI uses the profile or while a saved sign-in remains, so it removes the profile in both cases.
   When a sign-in might remain, `profile delete` warns about it before asking you to confirm and again in the `Login` field of its output.
1. Type the profile name when prompted to confirm.
1. Clean up each agent CLI that still uses the deleted profile:

   ```sh
   kong-harnesses profile cleanup --client CLIENT_NAME
   ```

   Omit `--client CLIENT_NAME` to clean up every supported agent CLI.
1. If `profile delete` warned that a saved sign-in might remain, import a valid copy of the profile again, run `kong-harnesses logout --profile PROFILE_NAME`, and then run `kong-harnesses profile delete PROFILE_NAME`.

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

If you kept kong-harnesses installed and only removed a profile or agent CLI settings, check the remaining state:

```sh
kong-harnesses status
```

The deleted profile no longer appears in the output, and cleaned agent CLIs don't show active kong-harnesses settings.
