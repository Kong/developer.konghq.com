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
  - text: "{{ site.claude_code }} compatibility testing"
    url: /ai-gateway/claude-code-compatibility/
  - text: "Proxy AI CLI tools through {{site.ai_gateway}}"
    url: /ai-gateway/ai-clis/
  - text: "Set up {{ site.claude_code }} with {{site.kong_harnesses}}"
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
  - text: "{{site.kong_harnesses}} profile create"
    url: /kong-harnesses/profile/create/
  - text: "{{ site.claude_code }} setup"
    url: https://code.claude.com/docs/en/setup
---

Kong tests each new {{ site.claude_code }} release through {{site.ai_gateway}} in four [provider modes](/ai-gateway/claude-code-compatibility/#provider-modes).
When a release fails in a tested mode, this page lists the affected release, what breaks, and how to avoid it.

Choose an approach based on your situation:

* **Your current release is broken**: [Turn off auto-updates](#turn-off-auto-updates), then [roll back to an earlier release](#roll-back-to-an-earlier-release).
* **You want to prevent broken updates**: Turn off auto-updates, check [Confirmed issues](#confirmed-issues), and [update manually](#update-manually).
* **You want slower updates that skip releases with major regressions**: [Follow the stable channel](#follow-the-stable-channel).

## Confirmed issues

No tested {{ site.claude_code }} release has a confirmed issue in the provider modes that Kong tests.
A release that isn't listed on this page might not have a test result yet.

## Turn off auto-updates

Turning off {{ site.claude_code }} auto-updates keeps an untested or broken release from installing automatically.

Homebrew and WinGet installs don't auto-update unless you set `CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE=1`, so leave that variable unset.
If you previously rolled back with `claude install`, follow the rest of this section because `claude install` adds a native build that updates itself.

[{{site.kong_harnesses}}](/kong-harnesses/) turns auto-updates off by default.
To check your profile, run [`{{site.kong_harnesses}} profile get`](/kong-harnesses/profile/get/):

```sh
kong-harnesses profile get PROFILE_NAME
```

If the `Auto-updates` line shows `On`, ask your administrator to create a new profile with [`{{site.kong_harnesses}} profile create`](/kong-harnesses/profile/create/) and `--auto-updates off`.

Until you get an updated profile, or if you don't use {{site.kong_harnesses}}, set `DISABLE_AUTOUPDATER` in your [{{ site.claude_code }} settings](https://code.claude.com/docs/en/setup#disable-auto-updates).
We recommend the settings file over a shell export because the settings file applies to every terminal and IDE session.

Add `"DISABLE_AUTOUPDATER": "1"` inside the `env` block of `~/.claude/settings.json`, keeping your existing settings:

```json
{
  "env": {
    "DISABLE_AUTOUPDATER": "1"
  }
}
```

You can also export `DISABLE_AUTOUPDATER=1` in your shell environment.

Activating a {{site.kong_harnesses}} profile that enables or omits auto-updates keeps a `DISABLE_AUTOUPDATER` value that you set.
Activation removes or restores only a value that an earlier activation wrote and that you didn't change.

`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` also turns off auto-updates, but some profile choices make activation write that variable blank.
Set `DISABLE_AUTOUPDATER` instead.
For the full activation rules, see [Claude Code choices](/kong-harnesses/profile-file/#claude-code-choices).

On a native or npm install, run `claude doctor` to confirm that auto-updates are off:

```sh
claude doctor
```

The `Auto-updates` line in the output starts with `disabled`.

## Update manually

Check [Confirmed issues](#confirmed-issues) for the release your install method offers before you run an update.
Skip the update if the list reports an issue for that release in your provider mode.

### Check the available release

Look up the release available for your install method:

* **Native**: Open Anthropic's [latest release file](https://downloads.claude.ai/claude-code-releases/latest), or the [stable release file](https://downloads.claude.ai/claude-code-releases/stable) if you follow the [stable channel](https://code.claude.com/docs/en/setup#configure-release-channel).
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

```powershell
winget upgrade Anthropic.ClaudeCode
```

{% endnavtab %}
{% endnavtabs %}

For other package managers, see [Update {{ site.claude_code }}](https://code.claude.com/docs/en/setup#update-claude-code).
{{ site.claude_code }} can notify you about an update before your package manager has it.
If your package manager doesn't offer the new release yet, wait and try again later.

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
> Running `claude install` installs a native build that updates itself unless `DISABLE_AUTOUPDATER=1` is set in your {{ site.claude_code }} settings or exported in your shell.
> An auto-update can then replace the release you install.
> See [Turn off auto-updates](#turn-off-auto-updates).

1. Install a working {{ site.claude_code }} release by replacing `VERSION` with the rollback release listed in [Confirmed issues](#confirmed-issues), or the release you used before the update:

   ```sh
   claude install VERSION
   ```

   If `claude install` reports an error, resolve it with [Troubleshoot installation](https://code.claude.com/docs/en/troubleshoot-install) before you continue.

1. Confirm that your shell runs the release you installed:

   ```sh
   claude --version
   ```

   If `claude --version` doesn't show the release you installed, follow [Check which executable runs](#check-which-executable-runs).

## Check which executable runs

When `claude --version` shows a different release than the one you installed, the native build is on another release, a custom launcher points at another release, or another `claude` binary comes first on your `PATH`.

{% navtabs "check-claude-executable" %}
{% navtab "macOS and Linux" %}

1. Run the native build by its full path to verify that the release you installed is present:

   ```sh
   ~/.local/bin/claude --version
   ```

   If the output shows a different release, run `claude install VERSION` again.
   If you replaced the `~/.local/bin/claude` launcher with your own launcher, point it at the release you installed, as [Auto-updates](https://code.claude.com/docs/en/setup#auto-updates) describes.

1. If the native build shows the release you installed, list every `claude` executable on your `PATH`:

   ```sh
   which -a claude
   ```

{% endnavtab %}
{% navtab "Windows" %}

1. Run the native build by its full path to verify that the release you installed is present.
   In PowerShell, run:

   ```powershell
   & "$env:USERPROFILE\.local\bin\claude.exe" --version
   ```

   In Command Prompt, run:

   ```text
   "%USERPROFILE%\.local\bin\claude.exe" --version
   ```

   If the output shows a different release, run `claude install VERSION` again.

1. If the native build shows the release you installed, list every `claude` executable on your `PATH`.
   In PowerShell, run:

   ```powershell
   Get-Command claude -All
   ```

   In Command Prompt, run:

   ```text
   where.exe claude
   ```

{% endnavtab %}
{% endnavtabs %}

Resolve any `PATH` or installation conflict:

* If the native build's folder isn't on your `PATH` or your shell can't find `claude`, add the folder as [Verify your PATH](https://code.claude.com/docs/en/troubleshoot-install#verify-your-path) shows.
* If another `claude` install still comes before the native build, remove that install as [Check for conflicting installations](https://code.claude.com/docs/en/troubleshoot-install#check-for-conflicting-installations) shows.

Confirm that `claude --version` shows the release you installed:

```sh
claude --version
```

## Follow the stable channel

The `stable` release channel delivers {{ site.claude_code }} updates later than the `latest` channel and skips releases with major regressions.

Before you switch channels, verify that [Confirmed issues](#confirmed-issues) doesn't list an issue for the stable release in your provider mode.
To see which release is on the stable channel, open Anthropic's [stable release file](https://downloads.claude.ai/claude-code-releases/stable) or, on Homebrew, run `brew info --cask claude-code`.
After each update, run `claude --version` and check the confirmed issues list for your provider mode.

{% navtabs "switch-stable-channel" %}
{% navtab "Native" %}

Add `"autoUpdatesChannel": "stable"` at the top level of `~/.claude/settings.json`, keeping your existing settings:

```json
{
  "autoUpdatesChannel": "stable"
}
```

`claude update` then follows the stable channel, even when the stable release is older than yours.
If you turn auto-updates on, they also follow the stable channel.
When auto-updates are off, run `claude update` whenever you want the current stable release.

To switch to the stable channel and keep your current release until the stable channel reaches a newer one, also set [`minimumVersion`](https://code.claude.com/docs/en/setup#pin-a-minimum-version) to your current release in `~/.claude/settings.json`:

```json
{
  "autoUpdatesChannel": "stable",
  "minimumVersion": "VERSION"
}
```

If you switch back to `latest` in `/config`, {{ site.claude_code }} clears `minimumVersion` from your settings.

To switch to the stable channel and install the stable release immediately instead of editing settings, run `claude install stable`:

```sh
claude install stable
```

`claude install stable` also saves the stable channel in your settings.
The stable release can be older than your current release.

{% endnavtab %}
{% navtab "npm or WinGet" %}

Anthropic documents the stable channel switch and `minimumVersion` for native installs only, so move to the native build first.

1. [Turn off auto-updates](#turn-off-auto-updates) if they're on.

1. Move to the native build at your current release by replacing `VERSION` with the release you have installed:

   ```sh
   claude install VERSION
   ```

1. Because both installs now report the same version, `claude --version` doesn't show which executable runs.
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

An install from the `apt`, `dnf`, or `apk` repositories gets its channel from the repository instead of the `autoUpdatesChannel` setting.
To switch to the stable channel, follow [Install with Linux package managers](https://code.claude.com/docs/en/setup#install-with-linux-package-managers).

On Alpine Linux, the `apk` steps add the `stable` repository line to `/etc/apk/repositories` and keep any `latest` line.
As root, replace the `latest` line with the `stable` line and update the package:

1. Remove the `latest` repository line from `/etc/apk/repositories`:

   ```sh
   sed -i '\|^https://downloads\.claude\.ai/claude-code/apk/latest$|d' /etc/apk/repositories
   ```

1. Check whether `/etc/apk/repositories` already contains the `stable` repository line:

   ```sh
   grep -xF "https://downloads.claude.ai/claude-code/apk/stable" /etc/apk/repositories
   ```

1. If the command doesn't print the `stable` URL, add the `stable` repository line:

   ```sh
   echo "https://downloads.claude.ai/claude-code/apk/stable" >> /etc/apk/repositories
   ```

1. Refresh the package index:

   ```sh
   apk update
   ```

1. Upgrade the package:

   ```sh
   apk upgrade claude-code
   ```

`apk` keeps your current release until the `stable` channel serves a newer one.

{% endnavtab %}
{% endnavtabs %}
