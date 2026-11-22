---
title: "{{ site.claude_code }} release known issues"
content_type: reference
layout: reference

description: "Known issues with {{ site.claude_code }} releases tested through {{site.ai_gateway}}, and steps to keep {{ site.claude_code }} on a working release."

breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-clis/

products:
  - ai-gateway

works_on:
  - on-prem
  - konnect

tags:
  - ai
  - anthropic
  - cli
  - compatibility
  - troubleshooting

related_resources:
  - text: "Proxy AI CLI tools through {{site.ai_gateway}}"
    url: /ai-gateway/ai-clis/
  - text: "Set up {{ site.claude_code }} with {{site.kong_harnesses}}"
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
  - text: "{{site.kong_harnesses}} profile create"
    url: /kong-harnesses/profile/create/
  - text: "{{ site.claude_code }} setup"
    url: https://code.claude.com/docs/en/setup
---

When the tests in [{{ site.claude_code }} provider modes](/ai-gateway/ai-clis/#claude-code-provider-modes) find a {{ site.claude_code }} release that fails in a tested mode, Kong lists the affected release, what breaks, and how to avoid it on this page.
To keep {{ site.claude_code }} on a working release, turn off auto-updates, update manually, roll back to an earlier release, or follow the stable channel.

## Confirmed issues

No tested {{ site.claude_code }} release has a confirmed issue in the provider modes that Kong tests.
A release that isn't listed on this page might not have a test result yet.

## Turn off auto-updates

Turning off {{ site.claude_code }} auto-updates keeps an untested or broken release from installing automatically.

[{{site.kong_harnesses}}](/kong-harnesses/) turns auto-updates off by default.
If your profile enables auto-updates or omits the setting, ask your administrator for a profile created with `--auto-updates off` using [`{{site.kong_harnesses}} profile create`](/kong-harnesses/profile/create/).

Until you get an updated profile, or if you don't use {{site.kong_harnesses}}, add `"DISABLE_AUTOUPDATER": "1"` to the `env` block of your [{{ site.claude_code }} settings](https://code.claude.com/docs/en/setup#disable-auto-updates), such as `~/.claude/settings.json`:

```json
{
  "env": {
    "DISABLE_AUTOUPDATER": "1"
  }
}
```

You can also export `DISABLE_AUTOUPDATER=1` in your shell environment.

When you activate a {{site.kong_harnesses}} profile that enables or omits auto-updates, activation doesn't set `DISABLE_AUTOUPDATER`.
If an earlier activation wrote `DISABLE_AUTOUPDATER` (for example, from a profile with auto-updates off) and your settings file still has the value that it wrote, activation restores the earlier value, or removes the key if it wasn't present before.
If you changed the value after that activation, activation keeps your value.
If no earlier activation wrote it, activation leaves `DISABLE_AUTOUPDATER` itself unchanged in your settings and doesn't override a `DISABLE_AUTOUPDATER` shell export.
`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` also turns off auto-updates, so a non-empty value in your settings or shell can still keep auto-updates off unless activation writes it blank for another enabled choice.
For when activation writes, keeps, or restores `DISABLE_AUTOUPDATER` and `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`, see [Claude Code choices](/kong-harnesses/profile-file/#claude-code-choices).

On a native or npm install, run `claude doctor` after setting `DISABLE_AUTOUPDATER` or activating a {{site.kong_harnesses}} profile to confirm that auto-updates are off:

```sh
claude doctor
```

The `Auto-updates` line in the output starts with `disabled`.

Homebrew and WinGet installs don't auto-update unless `CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE` is set to `1`, so leave that variable unset.

{:.warning}
> After you run `claude install`, you also have a native build on your computer.
> The native build updates itself unless `DISABLE_AUTOUPDATER=1` is set in your {{ site.claude_code }} settings or exported in your shell.

## Update manually

Before updating {{ site.claude_code }} manually, check which release you would get and skip the update if [Confirmed issues](#confirmed-issues) lists an issue for that release in your provider mode.

### Check the available release

Find the release that your install method offers before running an update:

* **Native installs**: Open Anthropic's [latest release file](https://downloads.claude.ai/claude-code-releases/latest), or the [stable release file](https://downloads.claude.ai/claude-code-releases/stable) if you follow the [stable channel](https://code.claude.com/docs/en/setup#configure-release-channel).
  When a native install uses the stable channel with [`minimumVersion`](https://code.claude.com/docs/en/setup#pin-a-minimum-version) set, the release you get can be the one you already have because auto-updates and `claude update` don't install a release below `minimumVersion`.
* **Homebrew**: Run `brew info --cask claude-code` or `brew info --cask claude-code@latest`, matching the cask you installed.
* **npm**: Run `npm view @anthropic-ai/claude-code version`.
* **WinGet**: Run `winget show Anthropic.ClaudeCode`.

### Run the update

Update {{ site.claude_code }} with the command for your install method:

{% navtabs "update-claude-code" %}
{% navtab "Native" %}

```sh
claude update
```

{% endnavtab %}
{% navtab "npm" %}

Check your npm version first:

```sh
npm --version
```

If you use npm 12, follow [Fix an npm 12 install](https://code.claude.com/docs/en/troubleshoot-install#fix-an-npm-12-install) instead.
Otherwise, update the global package:

```sh
npm install -g @anthropic-ai/claude-code@latest
```

{% endnavtab %}
{% navtab "Homebrew" %}

Update the `claude-code` cask:

```sh
brew upgrade claude-code
```

If you installed the `claude-code@latest` cask, update it instead:

```sh
brew upgrade claude-code@latest
```

{% endnavtab %}
{% navtab "WinGet" %}

{:.warning}
> Close {{ site.claude_code }} before you upgrade with WinGet.
> Windows locks the running executable, which can cause the upgrade to fail.

```sh
winget upgrade Anthropic.ClaudeCode
```

{% endnavtab %}
{% endnavtabs %}

For other package managers, see [Update {{ site.claude_code }}](https://code.claude.com/docs/en/setup#update-claude-code).
{{ site.claude_code }} can notify you about an update before your package manager has it, so if your package manager doesn't offer the new release yet, wait and try again later.

### Verify the updated release

Confirm the running {{ site.claude_code }} release:

```sh
claude --version
```

If the update command reports installing one release while `claude --version` shows another, follow [Check which executable runs](#check-which-executable-runs).

## Roll back to an earlier release

Rolling back {{ site.claude_code }} installs a native build at a release that worked in your provider mode, even if you originally installed {{ site.claude_code }} another way.

{:.warning}
> Turn off auto-updates before you roll back, even on a Homebrew or WinGet install.
> Running `claude install` installs a native build that updates itself unless `DISABLE_AUTOUPDATER=1` is set in your {{ site.claude_code }} settings or exported in your shell, which can replace the release you install.
> See [Turn off auto-updates](#turn-off-auto-updates).

1. Install a working {{ site.claude_code }} release by replacing `VERSION` with a release that worked in your provider mode:

   ```sh
   claude install VERSION
   ```

   If `claude install` reports an error, resolve it with [Troubleshoot installation](https://code.claude.com/docs/en/troubleshoot-install) before continuing.

1. Confirm that your shell runs the release you installed:

   ```sh
   claude --version
   ```

   If `claude --version` doesn't show the release you installed, follow [Check which executable runs](#check-which-executable-runs).

### Check which executable runs

When `claude --version` shows a different release than the one you installed, another `claude` binary or a custom launcher takes precedence on your `PATH`.

{% navtabs "check-claude-executable" %}
{% navtab "macOS and Linux" %}

1. Run the native build by its full path to verify that the target release is installed:

   ```sh
   ~/.local/bin/claude --version
   ```

   If you replaced the `~/.local/bin/claude` launcher with your own launcher, point it at the release you installed, as [Auto-updates](https://code.claude.com/docs/en/setup#auto-updates) describes.

1. If the native build shows the release you installed, list every `claude` executable on your `PATH`:

   ```sh
   which -a claude
   ```

{% endnavtab %}
{% navtab "Windows" %}

1. Run the native build by its full path to verify that the target release is installed.
   In PowerShell, run:

   ```powershell
   & "$env:USERPROFILE\.local\bin\claude.exe" --version
   ```

   In Command Prompt, run:

   ```cmd
   "%USERPROFILE%\.local\bin\claude.exe" --version
   ```

1. If the native build shows the release you installed, list every `claude` executable on your `PATH`:

   ```powershell
   where.exe claude
   ```

{% endnavtab %}
{% endnavtabs %}

Resolve any `PATH` or installation conflict:

* If the native build's folder isn't on your `PATH` or your shell can't find `claude`, add the folder as [Verify your PATH](https://code.claude.com/docs/en/troubleshoot-install#verify-your-path) shows.
* If another `claude` install still comes before the native build, remove that install as [Check for conflicting installations](https://code.claude.com/docs/en/troubleshoot-install#check-for-conflicting-installations) shows.

Confirm that `claude --version` now shows the release you installed before continuing:

```sh
claude --version
```

## Follow the stable channel

The stable release channel delivers {{ site.claude_code }} updates later than the latest channel and skips releases with major regressions.

Before switching channels, verify that [Confirmed issues](#confirmed-issues) doesn't list an issue for the stable release in your provider mode.
To see which release is on the stable channel, open Anthropic's [stable release file](https://downloads.claude.ai/claude-code-releases/stable) or, on Homebrew, run `brew info --cask claude-code`.
After each update, run `claude --version` and check the confirmed issues list for your provider mode.

{% navtabs "switch-stable-channel" %}
{% navtab "Native" %}

Configure the stable release channel in your {{ site.claude_code }} settings:

```json
{
  "autoUpdatesChannel": "stable"
}
```

`claude update` (and auto-updates if you turn them on) then follows the stable channel, even when the stable release is older than yours.
When auto-updates are off, run `claude update` whenever you want the current stable release.

To stay on your current release until the stable channel reaches a newer release, also set [`minimumVersion`](https://code.claude.com/docs/en/setup#pin-a-minimum-version) to your release, and don't run `claude install stable` (which installs the stable release immediately).
If you switch back to `latest` in `/config`, {{ site.claude_code }} clears `minimumVersion` from your settings.

To switch channels and install the stable release immediately instead of editing settings, run `claude install stable`:

```sh
claude install stable
```

That command also saves the stable channel in your settings.

{% endnavtab %}
{% navtab "npm or WinGet" %}

Anthropic documents the stable channel switch and `minimumVersion` for native installs only, so move to the native build first.

1. Keep `DISABLE_AUTOUPDATER=1` set in your {{ site.claude_code }} settings or exported in your shell because the native build updates itself (see [Turn off auto-updates](#turn-off-auto-updates)).

1. Move to the native build at your current release by replacing `VERSION` with the release you have installed:

   ```sh
   claude install VERSION
   ```

1. Because both installs now report the same version, `claude --version` can't tell you which executable runs.
   Run the `PATH` check in [Check which executable runs](#check-which-executable-runs), and remove the npm or WinGet install if it still comes before the native build.

1. Click the **Native** tab and follow those steps to switch to the stable channel.

{% endnavtab %}
{% navtab "Homebrew" %}

The `claude-code` cask already follows the stable channel.
If you previously ran `claude install` and the native build runs first on your `PATH`, click the **Native** tab and follow those steps instead.

If you installed the `claude-code@latest` cask, replace it with `claude-code` because the two casks can't be installed together.
Switching casks can install an older release than your current one.

1. Uninstall the `claude-code@latest` cask:

   ```sh
   brew uninstall --cask claude-code@latest
   ```

1. Install the `claude-code` cask:

   ```sh
   brew install --cask claude-code
   ```

{% endnavtab %}
{% navtab "apt, dnf, or apk" %}

Installs from the `apt`, `dnf`, and `apk` repositories choose a channel by repository instead of the `autoUpdatesChannel` setting.
To switch to the stable channel, follow [Install with Linux package managers](https://code.claude.com/docs/en/setup#install-with-linux-package-managers).

{% endnavtab %}
{% endnavtabs %}
