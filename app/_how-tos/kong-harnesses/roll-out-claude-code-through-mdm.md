---
title: Roll out {{ site.claude_code }} through MDM
content_type: how_to
permalink: /kong-harnesses/roll-out-claude-code-through-mdm/
breadcrumbs:
  - /kong-harnesses/

description: Build the {{ site.claude_code }} managed settings for a kong-harnesses profile, deploy them with your MDM tool, and let each developer sign in to {{site.ai_gateway}} as themselves.

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kong-harnesses

automated_tests: false

min_version:
  ai-gateway: '2.4'

tags:
  - ai
  - anthropic

related_resources:
  - text: Set up {{ site.claude_code }} with kong-harnesses
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
  - text: Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model
    url: /kong-harnesses/maintain-a-claude-code-fleet/
  - text: "{{ site.claude_code }} managed settings"
    url: https://code.claude.com/docs/en/managed-settings

prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: kong-harnesses
      content: |
        This guide uses [kong-harnesses](/kong-harnesses/) to build the managed settings.
        On the computer where you build the managed settings, install a kong-harnesses release that includes `fleet build` and `fleet remove`.

        {:.info}
        > **Supported computers:** kong-harnesses runs on macOS, on Windows 11, and on Linux desktops with Secret Service, such as Ubuntu 26.04, 24.04 and 22.04, and Red Hat Enterprise Linux 9, on amd64 and arm64.
        > Set it up on the desktop you work on, not in WSL, a container or an SSH session.

        {% navtabs "install-kong-harnesses" %}
        {% navtab "macOS" %}
        {% include tools/kong-harnesses/install/osx.md %}
        {% endnavtab %}
        {% navtab "Linux" %}
        {% include tools/kong-harnesses/install/linux.md %}
        {% endnavtab %}
        {% navtab "Windows" %}
        {% include tools/kong-harnesses/install/windows.md %}
        {% endnavtab %}
        {% endnavtabs %}

        To check that your release includes the fleet commands, run `kong-harnesses fleet build --help`.
        If the shell can't find `kong-harnesses`, open a new terminal.
    - title: A kong-harnesses profile
      content: |
        Create a kong-harnesses profile that signs developers in through your identity provider, as [Set up {{ site.claude_code }} with kong-harnesses](/ai-gateway/set-up-claude-code-with-kong-harnesses/) shows.
        Install kong-harnesses with that profile on the computer where you build the managed settings.
        This guide calls the profile `work`.

        The gateway origin of the profile must use `https://`.
        `kong-harnesses fleet build` refuses a profile with a plain `http://` gateway origin or with the Claude subscription sign-in.
    - title: A mobile device management tool
      content: |
        You need a mobile device management (MDM) tool that installs packages and a configuration profile or policy on the managed computers, such as Jamf Pro on macOS or Microsoft Intune on Windows.
        On Linux, you can use your configuration management tool.
        You also need administrator rights on one managed computer for each platform that you deploy to, to test the result.

tldr:
  q: How do I roll out {{ site.claude_code }} to every computer of my organization with kong-harnesses?
  a: |
    When the Claude provider of the profile is the Anthropic API, sign in to the profile first.
    Then run `kong-harnesses fleet build` for each platform.
    With your MDM tool, deploy {{ site.claude_code }}, kong-harnesses, the gateway's CA if it comes from a private CA, and the files that the build writes.
    Each developer then signs in as themselves on their first {{ site.claude_code }} request, and once more for each gateway MCP server that takes a key or its own sign-in.

cleanup:
  inline:
    - title: Remove the fleet build
      content: |
        For a build with `--mcp-servers allowlist` or `any`, first ask each developer who ran `profile activate` to remove the settings that it added, before you remove kong-harnesses from the computers:

        ```sh
        kong-harnesses profile cleanup --client claude-code
        ```

        [`profile cleanup`](/kong-harnesses/profile/cleanup/) changes only the developer's own {{ site.claude_code }} settings, so it works before or after you delete the files of the build, but it needs kong-harnesses on the computer.

        Then, as an administrator, remove the package or script that installs the files of the build from each assignment in your MDM tool, so that the tool doesn't install the files again after you delete them.
        For an Intune macOS app (PKG), remove the groups from its Required assignment, because Intune has no Uninstall assignment for that app type.

        Next, run `kong-harnesses fleet remove` with the record file of the build, and add the flags that the removal needs:

        * For an MDM build, pass the policy that the computers get now with `--policy`.
        * For a build with `--mcp-servers exclusive`, pass the `managed-mcp.json` that the computers have now with `--mcp-config`.
        * When policy keys or your own MCP servers are left, pass a new or empty folder with `--output-dir`.
          `fleet remove` writes what is left there, and asks for the flag when it needs it.

        Replace each placeholder with the value for your deployment, and keep the quotes that the examples show.
        For a file build without `--mcp-servers exclusive`, `fleet remove` prints the path of each file to delete from the managed computers:

        ```sh
        kong-harnesses fleet remove --record fleet-macos/kong-harnesses-fleet-BUILD_ID.json
        ```

        For a file build with `--mcp-servers exclusive`, replace `MCP_CONFIG_FILE` with a copy of the `managed-mcp.json` that the computers have now, and pass an output folder for your own servers that are left:

        ```sh
        kong-harnesses fleet remove --record fleet-macos/kong-harnesses-fleet-BUILD_ID.json --mcp-config 'MCP_CONFIG_FILE' --output-dir fleet-macos-removed
        ```

        For an MDM build without `--mcp-servers exclusive`, replace `POLICY_FILE` with the policy that the computers get now, and pass an output folder for the keys of your own policy that are left:

        ```sh
        kong-harnesses fleet remove --record fleet-macos-mdm/kong-harnesses-fleet-BUILD_ID.json --policy 'POLICY_FILE' --output-dir fleet-macos-removed
        ```

        For an MDM build with `--mcp-servers exclusive`, pass all the flags.
        Replace `POLICY_FILE` with the policy that the computers get now, and `MCP_CONFIG_FILE` with a copy of their `managed-mcp.json`:

        ```sh
        kong-harnesses fleet remove --record fleet-macos-mdm/kong-harnesses-fleet-BUILD_ID.json --policy 'POLICY_FILE' --mcp-config 'MCP_CONFIG_FILE' --output-dir fleet-macos-removed
        ```

        When keys of your own policy are left, `fleet remove` writes the policy without the settings of the build under `mdm` in the output folder.
        Where the value of the build is still in the policy, your earlier value comes back.
        A value that you changed after the build stays, unless it is the same as the value of the build, because `fleet remove` can't tell the two apart and takes it out too.
        `fleet remove` lists each value that it takes out or gives back, so check that list, and then deploy the policy in place of the current one.
        If no other settings are left, `fleet remove` tells you to remove the policy instead.

        When your own servers are left in `managed-mcp.json`, `fleet remove` writes the file under `root` in the output folder.
        `fleet remove` keeps a server whose definition changed after the build, even when it has the name of a gateway MCP server, and names each one that it keeps.
        Remove each kept server that still points to the gateway from the file before you install it.
        Install that `managed-mcp.json` in place of the one that the computers have.
        When no server is left, `fleet remove` prints the path of `managed-mcp.json` among the files to delete.

        Then, as an administrator, delete each file that `fleet remove` printed from each computer.
        On macOS, also remove the receipt of the package on each computer, so that your MDM tool installs a later package with the same identifier and version:

        ```sh
        sudo pkgutil --forget PACKAGE_IDENTIFIER
        ```
---

With `kong-harnesses fleet build`, you turn a kong-harnesses profile into [{{ site.claude_code }} managed settings](https://code.claude.com/docs/en/managed-settings) that your mobile device management (MDM) tool deploys to every managed computer.
With `--mcp-servers allowlist` or `any` and a profile with gateway MCP servers, each developer also runs `profile activate` to get those servers, as [Choose the MCP servers](#choose-the-mcp-servers) describes.
Developers don't install, import or edit anything else.
Each developer signs in as themselves, in the browser, on their first {{ site.claude_code }} request, and kong-harnesses renews the sign-in by itself.
For a profile with key servers, the gateway MCP servers that take a fixed key, each developer also runs `kong-harnesses login --profile work` once, and types the key of each key server.
For a gateway MCP server with its own sign-in, each developer signs in to it once from `/mcp` in {{ site.claude_code }}.

In this guide, you choose how the settings reach the computers and which MCP servers they allow, build the managed settings for each platform, check what they hold, and test them on one computer for each platform before the rest of the fleet.

## Sign in on your own computer

When the Claude provider of the profile is the Anthropic API, `fleet build` reads the model list of the gateway, with your own sign-in to the profile when there is one.
So the computer where you run `fleet build` must reach the gateway.
If the gateway asks for a sign-in and you aren't signed in, `fleet build` refuses to build and names `kong-harnesses login`.
It also refuses when the gateway refuses the sign-in or can't send the list, and when the gateway lists no model that `/model` can show.
For that provider, sign in to the profile first with [`kong-harnesses login`](/kong-harnesses/login/):

```sh
kong-harnesses login --profile work
```

For another Claude provider, such as Amazon Bedrock, `fleet build` uses only the models of the profile, doesn't read the model list of the gateway and doesn't need a sign-in.

## Choose how the settings reach the computers

{{ site.claude_code }} can get managed settings from several sources on one computer.
These are the administrator sources.
By default, it takes most keys from only the highest of these sources that sets a policy key to a value other than empty objects.
It reads [a few keys, such as `env`, from every source](https://code.claude.com/docs/en/managed-settings#keys-read-from-every-admin-source).
The sources, from highest to lowest:

1. Remote settings: server-managed settings from the claude.ai admin console, or from a Claude apps gateway.
1. An MDM policy: the `com.anthropic.claudecode` preference domain on macOS, or the `Settings` value under `HKLM\SOFTWARE\Policies\ClaudeCode` on Windows.
1. The managed settings file, `managed-settings.json`, with the files in its `managed-settings.d` folder.

On Windows, a developer can also write the `Settings` value under `HKCU\SOFTWARE\Policies\ClaudeCode`.
{{ site.claude_code }} uses that value only when [no administrator document is present](https://code.claude.com/docs/en/managed-settings#present-admin-documents), and no app that starts {{ site.claude_code }}, such as Claude Desktop, passes a setting that restricts Claude.
In WSL, {{ site.claude_code }} uses that value only when the `HKLM` policy, or `managed-settings.json` or a file in `managed-settings.d` under `C:\Program Files\ClaudeCode`, sets `wslInheritsWindowsSettings` to `true`.
The `HKCU` value must also set it to `true`, and the two conditions for Windows must also hold.

By default, `fleet build` writes its settings as a file in `managed-settings.d`.
This is a file build.
{{ site.claude_code }} merges that file over your own `managed-settings.json`.
The keys that the build doesn't set stay as your file sets them, lists combine, and a single value of the build replaces your value.
A value in your file that the build doesn't set, such as `forceLoginMethod` or `forceLoginGatewayUrl`, or a list entry, such as one in `allowedProviders`, can still send {{ site.claude_code }} around the gateway.
So `fleet build` refuses such a value in the `managed-settings.json` that you pass with `--policy`, but it doesn't check your other files in `managed-settings.d`.
The build also sets `ANTHROPIC_CUSTOM_HEADERS`, so its value replaces the one in your `managed-settings.json`.
A file build needs `--policy` or `--no-policy`.
If the computers have a `managed-settings.json`, pass a copy of it with `--policy`.
The build then keeps your headers in its value.
{{ site.claude_code }} reads the managed settings as the developer, so every account on the computer can read them, also the headers in them.
So put only headers that hold no secret in `ANTHROPIC_CUSTOM_HEADERS`.
The credential helper keeps the gateway credential of each developer out of the settings.
If the computers have no `managed-settings.json`, also when they have files in `managed-settings.d`, pass `--no-policy`.
For a file build, `--policy` takes only the `managed-settings.json` of the computers, and `fleet build` refuses every property list there, also a binary one.
For an MDM policy, build with `--delivery mdm` instead.

{{ site.claude_code }} merges the files in `managed-settings.d` in alphabetical order, and a later file replaces a single value of an earlier file.
`--policy` checks only `managed-settings.json`, so check each of your own files in `managed-settings.d`.
A file whose name sorts after `kong-harnesses.json` in alphabetical order must not set a key that the build sets, such as `apiKeyHelper` or a variable in `env`.
A file whose name sorts before `kong-harnesses.json` loses each value that the build sets, such as the headers in `ANTHROPIC_CUSTOM_HEADERS`, and `fleet build` doesn't tell you.
Move such headers into your `managed-settings.json`, and pass a copy of it with `--policy`, so that the build keeps them.
No file, in any order, may set `policyHelper`, because the settings that a policy helper computes replace all the other managed settings.
Also make sure that no file adds an `allowedProviders` entry, because {{ site.claude_code }} combines the lists of all the files in `managed-settings.d`, also the list of the build.
No file may set `forceLoginMethod` or `forceLoginGatewayUrl` either, because the build sets neither, so a value of either key in any file applies.
For a Windows build without `--wsl inherit`, each file must leave out `wslInheritsWindowsSettings` or set it to `false`.
{{ site.claude_code }} leaves the Windows chain off only for no key, `null`, `false` or `"false"`, and any other value turns it on, so {{ site.claude_code }} in WSL then reads the build, whose commands only Windows runs.

By default, on a computer whose {{ site.claude_code }} MDM policy sets a [policy key](https://code.claude.com/docs/en/managed-settings#how-claude-code-combines-managed-sources) to a value other than empty objects, {{ site.claude_code }} takes most keys from the MDM policy and ignores them in the file.
So the credential helper and the hooks of a file build don't apply there, and those computers need an MDM build.
An MDM policy that sets only the control keys, `managedSourcesBehavior` and `wslInheritsWindowsSettings`, doesn't count.
A value that {{ site.claude_code }} reads as unset, such as `null`, sets no key.
{{ site.claude_code }} still reads [a few keys from every administrator source](https://code.claude.com/docs/en/managed-settings#keys-read-from-every-admin-source), such as `env`.
One of them is the MCP lock that `--mcp-servers allowlist` sets, so the lock and its server list can still apply from the file.
But while the lock is on, {{ site.claude_code }} takes the server list from the highest administrator source that sets one.
So if the MDM policy on the computers sets its own `allowedMcpServers` list, that list replaces the list of the build.
If that list doesn't allow the addresses of the gateway MCP servers, {{ site.claude_code }} doesn't load them.

For every computer whose MDM policy sets a policy key to a value other than empty objects, build with `--delivery mdm`.
This is an MDM build.
If the computers get a {{ site.claude_code }} policy now, pass it with `--policy`.
If they don't get a {{ site.claude_code }} MDM policy of your own, pass `--no-policy`.
The build sets `ANTHROPIC_CUSTOM_HEADERS` in the policy, and {{ site.claude_code }} [takes each `env` variable](https://code.claude.com/docs/en/managed-settings#keys-read-from-every-admin-source) from the highest administrator source that sets it.
So the value of the build replaces the one in your `managed-settings.json` and in `managed-settings.d`.
The build keeps only the headers of the policy that you pass with `--policy`, so put each header that the computers need in that policy.
As for a file build, every account on the computer can read these headers, so they must hold no secret.
On macOS, the policy is the XML property list of the Custom Settings payload for the `com.anthropic.claudecode` preference domain.
On Windows, the policy is a JSON file with exactly the text of the `Settings` registry value, not a `.reg` export.

If your organization sets `managedSourcesBehavior` to `merge`, {{ site.claude_code }} applies your managed settings file and the MDM policy of the build together.
{{ site.claude_code }} reads `managedSourcesBehavior` only from the highest source that has it or a policy key, so for an MDM build, the policy that you pass with `--policy` must set it.
If only your `managed-settings.json` sets it, put it in a policy file, and pass that file with `--policy` in place of `--no-policy`.
On computers with an MDM policy, a file build doesn't work with `merge` either, because {{ site.claude_code }} reads `apiKeyHelper` only from the highest source.
With `merge`, also check your `managed-settings.json` and the files in `managed-settings.d`, because {{ site.claude_code }} merges them with the MDM policy.
A lower source [adds its list entries](https://code.claude.com/docs/en/managed-settings#compose-every-managed-source), such as `permissions.allow` rules and `hooks`, and supplies each key that the MDM policy leaves unset, such as `model`.
A [restriction allowlist](https://code.claude.com/docs/en/settings-reference#managedsourcesbehavior), such as `allowedProviders`, still comes whole from the highest source that sets one, so there the list of the build applies.
Remove each value that conflicts with the build, and each list entry or key that you don't want on the computers.
Login keys, such as `forceLoginMethod` and `forceLoginGatewayUrl`, still come only from the highest MDM policy or file with a policy key.
Linux doesn't have an MDM policy, so on Linux the settings always go in a file.

`fleet build` refuses a policy that would stop {{ site.claude_code }} from reaching the gateway, and names the value.
It lists each of your values that it changes.

If you keep {{ site.claude_code }} policy in the claude.ai admin console or on a Claude apps gateway, move it into your MDM policy or your `managed-settings.json`.
Then remove it from its source.
{{ site.claude_code }} fetches remote settings only in [the cases that the source ranking lists](https://code.claude.com/docs/en/managed-settings#how-claude-code-combines-managed-sources):

* The session has one of the credentials that [Platform availability](https://code.claude.com/docs/en/server-managed-settings#platform-availability) lists, such as a Team or Enterprise claude.ai login, an OAuth token in `CLAUDE_CODE_OAUTH_TOKEN` or an API key that is set directly.
* The session signs in to a Claude apps gateway with `/login`.
* The session runs in the Code tab of Claude Desktop behind a Claude apps gateway that serves settings to it.

The build itself puts a session in none of these cases.
The key that the build's `apiKeyHelper` returns isn't one of those credentials.
A `/login` sign-in to a gateway needs `forceLoginMethod` and `forceLoginGatewayUrl` in your managed settings, which `fleet build` refuses in your policy.
The gateway of the profile is a {{ site.ai_gateway_name }}, not a Claude apps gateway.
But on a computer where a developer kept a claude.ai login of your organization, {{ site.claude_code }} can still fetch them.
The remote settings then rank above the build, and the build's `apiKeyHelper` isn't in effect.

## Choose the MCP servers

`--mcp-servers` sets which MCP servers {{ site.claude_code }} loads on the managed computers.
Without this flag, `fleet build` uses `allowlist`, but only for a profile without gateway MCP servers.
For a profile with gateway MCP servers, `fleet build` refuses the build until you choose a mode with this flag.
For a profile without gateway MCP servers, use `allowlist` or `any`.
When the profile has gateway MCP servers, a `managed-mcp.json` on the computers or some of your own managed settings can make `exclusive` the only mode that loads them.

* `--mcp-servers exclusive` gives every developer the gateway MCP servers of the profile.
  It needs a profile with at least one gateway MCP server.
  The build writes the servers to `managed-mcp.json` under `root`, also for an MDM build.
  {{ site.claude_code }} then loads only the servers in that file and other servers that the [managed MCP docs](https://code.claude.com/docs/en/managed-mcp#exclusive-control-with-managed-mcp-json) list, such as the servers that `managedMcpServers` provides and the connectors that Claude Desktop delivers.
  It loads no server that a developer, a project or a plugin adds.
  To keep your own servers in that file, pass the `managed-mcp.json` that the computers have with `--mcp-config`.
  This mode doesn't take `--mcp-url` or `--mcp-command`.
* `--mcp-servers allowlist` locks {{ site.claude_code }} to the servers that your own managed settings provide or allow, the gateway MCP servers of the profile, and the servers that you list with `--mcp-url` or `--mcp-command`.
  It doesn't add servers.
  To get the gateway MCP servers, each developer runs [`kong-harnesses profile activate`](/kong-harnesses/profile/activate/), which adds them as a plugin in the `skills` folder of the developer's {{ site.claude_code }} settings:

  ```sh
  kong-harnesses profile activate work --client claude-code
  ```

* `--mcp-servers any` doesn't add a lock or servers, and leaves MCP servers to each developer.
  To get the gateway MCP servers, each developer runs `profile activate`, as with `allowlist`.
  A lock that your own managed settings set still applies.
  This mode doesn't take `--mcp-url` or `--mcp-command`.

With `allowlist` or `any`, {{ site.claude_code }} doesn't load the gateway MCP servers, even after `profile activate`, in these cases:

* The computers already have a `managed-mcp.json`.
  {{ site.claude_code }} then loads only the servers in that file and the [exceptions of exclusive control](https://code.claude.com/docs/en/managed-mcp#exclusive-control-with-managed-mcp-json), such as the servers that `managedMcpServers` provides, as with `exclusive`.
  It doesn't load the servers of the plugin that `profile activate` adds.
* Your own managed settings set `strictPluginOnlyCustomization` to `true`, or to a list with one or more kinds, such as `mcp`.
* Your own managed settings set `strictKnownMarketplaces`, or [its alias](https://code.claude.com/docs/en/settings-reference#marketplace-key-aliases) `allowedMarketplaces`, without a `{"source": "skills-dir"}` entry, or `blockedMarketplaces` with one.

When the policy that you pass with `--policy` sets one of these values, `fleet build` refuses `allowlist` and `any` for a profile with gateway MCP servers.
For a value that only the computers have, such as a `managed-mcp.json`, check the computers yourself.

In each case, {{ site.claude_code }} [skips the plugin](https://code.claude.com/docs/en/plugins/loading#skills-directory-plugins-blocked-by-managed-settings) that `profile activate` adds, or the servers in it.
If the profile has gateway MCP servers, use `exclusive`, and if the computers have a `managed-mcp.json`, pass it with `--mcp-config`.
`exclusive` doesn't work with `--wsl inherit`, which [Build the managed settings](#build-the-managed-settings) describes.
For Windows computers that need {{ site.claude_code }} in WSL, remove the setting or the `managed-mcp.json` that blocks the plugin, and use `allowlist` or `any`, so that {{ site.claude_code }} on Windows loads the gateway MCP servers.
{{ site.claude_code }} in WSL doesn't load them in any mode.
Otherwise, use `exclusive`, and leave out `--wsl inherit`.

With `allowlist`, {{ site.claude_code }} stops each server that a developer, a project, a plugin or claude.ai adds, or that a developer passes with `--mcp-config`, and that the allowlist doesn't match.
Among the servers that [skip the allowlist check](https://code.claude.com/docs/en/managed-mcp#servers-that-skip-the-allowlist-check) are:

* Each `managedMcpServers` entry.
* Each `managed-mcp.json` entry that uses no `${VAR}` expansion outside `env`.
* Built-in servers, such as Claude in Chrome, the `ide` server that {{ site.claude_code }} connects to in a running VS Code or JetBrains IDE, and servers that the CLI itself configures.
* The Slack tools of a Claude Tag session.
* The in-process `type: "sdk"` servers of an Agent SDK app.

With `exclusive`, {{ site.claude_code }} stops every server outside `managed-mcp.json`, apart from the [exceptions of exclusive control](https://code.claude.com/docs/en/managed-mcp#exclusive-control-with-managed-mcp-json).

In every mode, when a session starts or resumes, a hook of the build names the servers that {{ site.claude_code }} doesn't load, as [Check what the build holds](#check-what-the-build-holds) describes.
`kong-harnesses doctor` also names each one.

In every mode, a `deniedMcpServers` entry blocks each server that it matches, also a gateway MCP server, but not the in-process `type: "sdk"` servers of an Agent SDK app.
{{ site.claude_code }} combines the entries from all settings, also from the settings of a developer.
Make sure that your own managed settings don't deny a gateway MCP server.

## Build the managed settings

Run `fleet build` once for each platform of your managed computers.
`--platform` names the platform of the managed computers, so you can build for every platform on the same computer.
Each install command that a build prints runs from a copy of the build's files: the whole output folder on macOS, or its `root` folder on Linux and Windows, as [Install on the managed computers](#install-on-the-managed-computers) describes.
Set `--executable` to the absolute path where the kong-harnesses package installs the binary on the managed computers.
The filename must be `kong-harnesses`, or `kong-harnesses.exe` on Windows.
On Windows, the path must start with a drive letter, such as `C:\`, and use backslashes, so `fleet build` refuses a path with `/` or a network path.
It also must not have `"`, `%`, `!` or a control character, because the helper commands of the build can't carry them.
On macOS and Linux, it must not have a line break or a NUL, and for a macOS MDM build, no control character.
Each build needs its own output folder, and the folder must be new or empty.
This guide uses one folder for each build.

Replace each placeholder with the value for your deployment, and keep the quotes that the examples show, so that a path with spaces works:

* Replace `MCP_MODE` with the mode that you chose in [Choose the MCP servers](#choose-the-mcp-servers): `exclusive`, `allowlist` or `any`.
  With `exclusive`, if the computers have a `managed-mcp.json`, also add `--mcp-config` with a copy of that file.
  With `allowlist`, to let developers add servers of their own, also add `--mcp-url` with the URL pattern of each remote server, or `--mcp-command` with the command of each local server as a JSON array of strings.
* For a file build, replace `POLICY_FILE` with the path of your copy of `managed-settings.json`.
  If the computers have no `managed-settings.json`, also when they have files in `managed-settings.d`, replace `--policy 'POLICY_FILE'` with `--no-policy`.
* For an MDM build, replace `POLICY_FILE` with the path of your current policy, such as `com.anthropic.claudecode.plist` on macOS or `Settings.json` on Windows.
  If the computers don't get a {{ site.claude_code }} MDM policy of your own, replace `--policy 'POLICY_FILE'` with `--no-policy`.

Claude Desktop, an IDE extension or an Agent SDK app can start {{ site.claude_code }} and pass settings of its own, the host settings.
When the computer has managed settings, {{ site.claude_code }} ignores the host settings by default.
To [merge them](https://code.claude.com/docs/en/managed-settings#let-an-embedding-host-add-policy), add `--host-settings merge`, which sets `parentSettingsBehavior` to `merge` and replaces the value that your own policy sets.
{{ site.claude_code }} reads this key only from the managed source that it takes most keys from, so the build must be that source.
{{ site.claude_code }} then keeps only the host settings that restrict what Claude can do, with two exceptions.
The permission allow rules of the host still apply, unless your own managed settings set `allowManagedPermissionRulesOnly`.
The sandbox allowlists of the host still apply, unless your own managed settings set `sandbox.network.allowManagedDomainsOnly` for domains and `sandbox.filesystem.allowManagedReadPathsOnly` for read paths.
[Restrict parent settings](https://code.claude.com/docs/en/claude-apps-gateway#restrict-parent-settings) lists all the locks.

The Windows examples set up {{ site.claude_code }} on Windows itself.
By default, {{ site.claude_code }} in WSL on those computers doesn't use the settings.
To give it the same settings, add `--wsl inherit`.
{{ site.claude_code }} in each WSL distribution is a separate Linux install, and it must be at a version that Kong supports.
`fleet build` doesn't install it, and the Windows install of {{ site.claude_code }} doesn't put it in WSL.
To install it, see [Install in WSL](https://code.claude.com/docs/en/setup#install-in-wsl), and to find the supported versions, see [Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model](/kong-harnesses/maintain-a-claude-code-fleet/).
`fleet build` checks `wslInheritsWindowsSettings` only in the policy that you pass with `--policy`.
If that policy sets it to a value other than `null`, `false` or `"false"`, `fleet build` refuses a Windows build without `--wsl inherit`, so add the option or set the key to `false` in the policy.
`fleet build` can't see the computers, so it doesn't check the `HKLM` policy, `managed-settings.json` or the files in `managed-settings.d` there, unless you pass one of them with `--policy`.
If one of them sets `wslInheritsWindowsSettings` to a value other than `null`, `false` or `"false"`, {{ site.claude_code }} in WSL reads the build, and the credential helper and the hooks of a build without `--wsl inherit` don't run there.
For those computers, add `--wsl inherit`, or set the key to `false` there.
For a new MDM build of computers that already have an MDM build, which you pass with `--record`, `fleet build` first takes the settings of the earlier build out of the policy, and checks only the value that is left.
`--wsl inherit` needs Windows interop, which lets WSL run Windows programs, in each WSL distribution.
If interop is off, the credential helper tells the developer to turn it on.
`--wsl inherit` doesn't work with `--mcp-servers exclusive`, because {{ site.claude_code }} in WSL reads `managed-mcp.json` only from `/etc/claude-code`.
{{ site.claude_code }} in WSL gets the managed settings and the route to the gateway.
But with `allowlist` or `any`, it doesn't load the gateway MCP servers either, because `profile activate` on Windows adds them only to the {{ site.claude_code }} settings in the developer's Windows home folder.
For a profile with gateway MCP servers, the WSL line in the result of `fleet build` names the servers that {{ site.claude_code }} in WSL doesn't get.
With `--wsl inherit`, `fleet build` also refuses an `--executable` path with `'`.
It also refuses a `--policy` whose `env` sets `NODE_EXTRA_CA_CERTS`, `CLAUDE_CODE_CLIENT_CERT` or `CLAUDE_CODE_CLIENT_KEY`, because {{ site.claude_code }} in WSL can't read a Windows path of a certificate file.
`fleet build` checks only the `--policy` file for these variables, but {{ site.claude_code }} reads `env` from [every administrator source](https://code.claude.com/docs/en/managed-settings#keys-read-from-every-admin-source).
So also make sure that the `HKLM` policy, `managed-settings.json` and the files in `managed-settings.d` on the computers don't set them in `env`.
A gateway certificate from a private CA also needs that CA in each WSL distribution.
The developer controls the WSL distribution, so there the gateway lock holds only while the developer runs an unchanged {{ site.claude_code }}.

### File build

{% navtabs "fleet-build" %}
{% navtab "macOS" %}

```sh
kong-harnesses fleet build \
  --profile work \
  --platform macos \
  --executable /usr/local/bin/kong-harnesses \
  --policy 'POLICY_FILE' \
  --mcp-servers MCP_MODE \
  --output-dir fleet-macos
```

{% endnavtab %}
{% navtab "Linux" %}

```sh
kong-harnesses fleet build \
  --profile work \
  --platform linux \
  --executable /usr/bin/kong-harnesses \
  --policy 'POLICY_FILE' \
  --mcp-servers MCP_MODE \
  --output-dir fleet-linux
```

{% endnavtab %}
{% navtab "Windows" %}

```powershell
kong-harnesses fleet build --profile work --platform windows --executable 'C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe' --policy 'POLICY_FILE' --mcp-servers MCP_MODE --output-dir fleet-windows
```

{% endnavtab %}
{% endnavtabs %}

### MDM build

{% navtabs "fleet-build-mdm" %}
{% navtab "macOS" %}

```sh
kong-harnesses fleet build \
  --profile work \
  --platform macos \
  --delivery mdm \
  --executable /usr/local/bin/kong-harnesses \
  --policy 'POLICY_FILE' \
  --mcp-servers MCP_MODE \
  --output-dir fleet-macos-mdm
```

{% endnavtab %}
{% navtab "Windows" %}

```powershell
kong-harnesses fleet build --profile work --platform windows --delivery mdm --executable 'C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe' --policy 'POLICY_FILE' --mcp-servers MCP_MODE --output-dir fleet-windows-mdm
```

{% endnavtab %}
{% endnavtabs %}

`fleet build` writes the files that each computer needs under `root` in the output folder, at the path that each file takes on the computer.
A macOS build also writes the preinstall script of the package under `scripts` in the output folder.
An MDM build also writes the policy with your keys and its own settings under `mdm` in the output folder.
On macOS, the policy is `com.anthropic.claudecode.plist`, for a Custom Settings payload.
On Windows, the policy is `Settings.json`.
Its one line is the text for the `Settings` registry value.
`fleet build` prints what the settings hold and how to install them.

## Check what the build holds

The build writes these files under `root`:

{% table %}
columns:
  - title: Platform
    key: platform
  - title: Managed settings, for a file build
    key: settings
  - title: Profile
    key: profile
  - title: "MCP servers, with `--mcp-servers exclusive`"
    key: servers
rows:
  - platform: macOS
    settings: "`/Library/Application Support/ClaudeCode/managed-settings.d/kong-harnesses.json`"
    profile: "`/Library/Application Support/kong-harnesses/profiles/work.json`"
    servers: "`/Library/Application Support/ClaudeCode/managed-mcp.json`"
  - platform: Linux
    settings: "`/etc/claude-code/managed-settings.d/kong-harnesses.json`"
    profile: "`/etc/kong-harnesses/profiles/work.json`"
    servers: "`/etc/claude-code/managed-mcp.json`"
  - platform: Windows
    settings: "`C:\\Program Files\\ClaudeCode\\managed-settings.d\\kong-harnesses.json`"
    profile: "`C:\\Program Files\\kong-harnesses\\profiles\\work.json`"
    servers: "`C:\\Program Files\\ClaudeCode\\managed-mcp.json`"
{% endtable %}

The managed settings, in the file or in the MDM policy, hold what `kong-harnesses profile activate` writes for one developer, for every account on the computer.
With `allowlist` or `any`, the gateway MCP servers are the exception, because each developer adds them with `profile activate`.
The managed settings hold:

* The credential helper, which runs `kong-harnesses credential --profile work` from the path of `--executable`.
  For a `--wsl inherit` build, {{ site.claude_code }} in WSL runs it through Windows interop.
  The settings don't hold a credential, but every account on the computer can read them, so the headers in them must hold no secret, as [Choose how the settings reach the computers](#choose-how-the-settings-reach-the-computers) describes.
* Hooks that run kong-harnesses from the path of `--executable`, also through Windows interop in WSL for a `--wsl inherit` build.
  When a session starts or resumes, one hook names the MCP servers in the user or local settings, or in the `.mcp.json` of the project, that {{ site.claude_code }} doesn't load.
  It names up to 10 of them for each cause, with a count of the rest.
  It doesn't name the servers of a plugin.
  When the gateway or the profile marks a model as one that can't run WebSearch, another hook tells that model that no search ran.
  If the managed settings that {{ site.claude_code }} applies set [`disableAllHooks`](https://code.claude.com/docs/en/settings-reference#disableallhooks) to `true`, such as from your `--policy` or from a file in `managed-settings.d`, {{ site.claude_code }} turns off both hooks.
  Then no session names the MCP servers that it doesn't load, and no model learns that a WebSearch didn't run, but the credential helper still works.
* The models of the gateway.
  The settings set the default model of each Claude family, and the model of other roles such as subagents, to the models of the profile, or to the models that you name with `--model`, such as `--model MODEL_ID`.
  Each `--model` replaces the model of the family that it names, and of each role, such as subagents, that used the earlier model of that family.
  The other families and their roles keep the models of the profile.
  For a model ID that doesn't name exactly one Claude family, add the family, such as `--model opus=MODEL_ID`.
  When the Claude provider is the Anthropic API, {{ site.claude_code }} also asks the gateway for its model list.
  A model that the gateway adds later then shows in `/model` without a new build when its ID contains `claude` or `anthropic`.
  {{ site.claude_code }} [fetches the list again at each startup](https://code.claude.com/docs/en/llm-gateway-protocol#picker-entries-and-caching), so a developer restarts {{ site.claude_code }} to see the new model.
  Another new model needs a new build.
  With [`availableModels`](https://code.claude.com/docs/en/model-config#restrict-model-selection) in your managed settings, [discovery](https://code.claude.com/docs/en/llm-gateway-protocol#model-discovery) adds only the models that the list allows, and with `replaceBuiltInOptions` in `modelPicker`, {{ site.claude_code }} hides the discovered models from `/model`.
  By default, [a model ID entry](https://code.claude.com/docs/en/settings-reference#availablemodelsmatch) of `availableModels` also allows each later model ID that extends it, and a family alias such as `opus` allows the whole family.
  A later model that `availableModels` doesn't allow, or any new model while `replaceBuiltInOptions` is set, needs a change to that key, and for an MDM build, also a new build with the changed `--policy`.
  When the profile or the gateway has a model whose ID discovery skips, the build writes its own `modelPicker`, which replaces the whole `modelPicker` of your `--policy`, also its `replaceBuiltInOptions`.
  `fleet build` then names `modelPicker` among the values that it changes, so check the `modelPicker` in the output before you deploy the build.
  For another Claude provider, `/model` shows only the models of the build.
* The gateway prices of the models for `/cost`, when the gateway or the profile states them.
* The {{ site.claude_code }} features that the profile turns off behind the gateway.
* A lock to the gateway.
  {{ site.claude_code }} refuses every provider but the gateway, and ignores another Claude provider, a credential or custom headers that a developer sets in the shell or in their own settings.
  A session that Claude Desktop starts is the exception, because {{ site.claude_code }} then takes environment variables from the environment that Claude Desktop builds.
  For the settings that such an app passes, see `--host-settings merge` in [Build the managed settings](#build-the-managed-settings).
* With `--mcp-servers allowlist`, the lock on MCP servers that [Choose the MCP servers](#choose-the-mcp-servers) describes.
* A build ID in `env.KONG_HARNESSES_FLEET_BUILD`, so a support report from a developer names the build that their computer has.

The profile becomes a machine-wide profile on each computer.
kong-harnesses uses it before a developer's own profile with the same name, and developers can't change it.
kong-harnesses uses the file only when its owner and the accounts that can write to it, and to its folders, follow the rule for the platform in [Install on the managed computers](#install-on-the-managed-computers).
Otherwise, it refuses the profile, because another account could send every developer's sign-in to an identity provider that it controls.

`fleet build` also writes a record file, `kong-harnesses-fleet-BUILD_ID.json`, in the output folder, outside `root`.
`BUILD_ID` is the build ID that `fleet build` prints.
Keep the record with your policy.
You need it to remove the build, and to update an MDM build or a build with `--mcp-servers exclusive`, as [Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model](/kong-harnesses/maintain-a-claude-code-fleet/) shows.
You can't create it again.

## Install on the managed computers

With your MDM tool, first install the following on one test computer for each platform.
After the checks in [Validate](#validate) pass on each test computer, install them on the other managed computers:

1. {{ site.claude_code }}, at a version that Kong supports.
   `fleet build` doesn't install it.
   To install it, see [Set up {{ site.claude_code }}](https://code.claude.com/docs/en/setup).
   An older {{ site.claude_code }} doesn't refuse every other provider.
   To find the supported versions and hold the fleet to them, see [Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model](/kong-harnesses/maintain-a-claude-code-fleet/).
1. The kong-harnesses package for the platform, at the path of `--executable`: the macOS installer package at `/usr/local/bin/kong-harnesses`, the Linux `.deb` or `.rpm` package at `/usr/bin/kong-harnesses`, or the Windows installer at `C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe`.
   To install them, and to deploy the Windows installer with Intune, see [Install kong-harnesses for every user of a computer](/kong-harnesses/install/).
   Don't install kong-harnesses with Homebrew on a managed computer.
   On an Intel Mac, Homebrew uses the same `/usr/local/bin` path as the package.
1. The CA of the gateway in the system trust store, if the gateway certificate comes from a private CA.
   The build doesn't install a CA.
1. The files under `root` in the output folder, with their paths, as an administrator.
   On macOS and Linux, root must own each file and every folder above it, and no group or other account can write to them.
   On Windows, only SYSTEM, Administrators or TrustedInstaller can own or write to each file and every folder up to `C:\Program Files`, and no reparse point can be on the path.
   A reparse point, such as a symbolic link or a junction, sends the path to another place.
1. For an MDM build, the policy under `mdm` in the output folder, in place of the {{ site.claude_code }} policy that the computers get now.
   On macOS, upload `com.anthropic.claudecode.plist` to your MDM tool in place of your Custom Settings payload for the `com.anthropic.claudecode` preference domain.
   If the computers don't get a {{ site.claude_code }} policy yet, upload it as a Custom Settings payload for that domain.
   On Windows, set the `REG_SZ` value `Settings` under `HKLM\SOFTWARE\Policies\ClaudeCode` to the line in `Settings.json`, in place of the JSON that the value holds.
   If the computers don't get a policy yet, set the value through Group Policy, Intune or your own tool.
   Computers that already get a {{ site.claude_code }} policy need a build with `--policy`.
   If an earlier file build installed `managed-settings.d/kong-harnesses.json` on the computers, delete that file, because {{ site.claude_code }} still reads its `env` and its MCP server lock.

`fleet build` prints the command that packages or copies the files for the platform.
The command runs from inside a copy of the build's files, so it can run on a computer other than the one that runs `fleet build`.
On macOS, copy the whole output folder of the build to the Mac that builds the package, with a tool such as `ditto` or `rsync -a`.
Then run the command there, from inside the copied output folder.
The command sets the modes of the files and the preinstall script again, so a copy that lost them still gives a correct package, and then `pkgbuild` puts the files and the preinstall script in one package.
Replace `PACKAGE_IDENTIFIER` and `PACKAGE_VERSION` with the values for your package.
`fleet build` prints this command:

```sh
find root scripts -type d -exec chmod 755 {} + && find root -type f -exec chmod 644 {} + && chmod 755 scripts/preinstall && pkgbuild --root root --scripts scripts --install-location / --identifier PACKAGE_IDENTIFIER --version PACKAGE_VERSION kong-harnesses-fleet.pkg
```

The command writes `kong-harnesses-fleet.pkg` in that folder, and it doesn't sign the package.
Several MDM delivery paths need a signed package:

* [Apple MDM](https://support.apple.com/guide/deployment/distribute-packages-to-mac-computers-dep873c25ac4/web) installs only a package with a signature that the Mac can verify.
* A Jamf Pro PreStage enrollment package needs a certificate that the Mac trusts at enrollment.

For those paths, sign the package with your installer identity:

```sh
productsign --sign 'INSTALLER_IDENTITY' kong-harnesses-fleet.pkg kong-harnesses-fleet-signed.pkg
```

For Microsoft Intune, add the package as a [macOS app (PKG)](https://learn.microsoft.com/en-us/intune/app-management/deployment/add-unmanaged-pkg-macos), which takes an unsigned package and a package that installs files outside `/Applications`.
Intune uses the app bundle IDs of the Included apps list to detect the installation, and this package installs no app, so Intune may not report it as installed.
An Intune macOS line-of-business app doesn't fit, because Intune [needs a package](https://learn.microsoft.com/en-us/intune/app-management/deployment/add-lob-macos#app-requirements) that a Developer ID Installer certificate signs, and reports its install only for apps in the `Applications` folder, and this package has none.
Then install the package on each computer: the signed copy, or the unsigned `kong-harnesses-fleet.pkg` only for a path that takes it.

On Linux and Windows, copy the `root` folder from the output folder to each computer.
Run the copy command there as an administrator, from inside the copied `root` folder.
On Windows, run it in Windows PowerShell.
On Linux, the copy command needs `getfacl`, from the `acl` package.

Before the install writes a file, it checks each file and folder of the build that is already on the computer.
It also checks the folders above the files, such as `/etc` on Linux, `/Library` on macOS and `C:\Program Files` on Windows.
On macOS and Linux, the install stops before it writes any file when an entry is a link, has another hard link, has an owner other than root, or its group or other accounts can write to it.
On Linux, it also stops for an entry with ACL entries beyond its mode bits, and for a name with a control character in the copy.
On macOS, it also stops for an ACL entry that lets an account other than root change the entry, also an inherited one.
On Windows, it stops for a link or another hard link, and when the owner of an entry, or an account that can change it, isn't Administrators, SYSTEM, TrustedInstaller or CREATOR OWNER.
The account that runs the command doesn't count as one of them.
The install also stops when it can't list, read or check an entry:

* `cannot be listed`: on Linux, the install can't enter or list the copy, `find` fails on a path, or the check doesn't get through the whole listing.
  The error of `find` above the message names the path that it can't list.
  On macOS, `find` fails on a path.
  On Windows, the install can't list the copy or a folder in it, and the message names that folder.
* `cannot be read`: on macOS, the install can't read the ACL of a path, and on Windows, it can't read a path, its owner or its ACL.
* `cannot be checked for its owner, because the account that runs the step cannot be read`: on macOS and Linux, the `id` command fails.
* `cannot be checked for ACL entries; install the acl package, which has getfacl`: on Linux, `/usr/bin/getfacl` isn't there.
* `cannot be checked for ACL entries: getfacl failed with exit status STATUS`: on Linux, `getfacl` is there and fails, with the exit status in place of `STATUS`.
* `cannot be checked for hard links`: on Windows, `fsutil` doesn't start, exits with a code other than 0, or prints no record that names the file itself.

Each stop prints one message that starts with `Not installed:`, and then names the path and the condition, such as `has another owner`.
On Windows, the message builds each path from the copy folder and the destination as the command got them, so a path can look different from the one that File Explorer shows.
Remove or fix that entry, or the cause that the condition names, and then run the install again.

On Linux and Windows, the install stops with `could not be written in full; fix the cause and run the step again` when the copy fails after the checks, or when a change of the owner, the modes or the access rules fails.
The build can then be partly written on the computer, so run the install again after the fix.

On macOS and Linux, after the install, root owns each file and folder of the build, with mode 755 for each folder and mode 644 for each file, so each account on the computer can read them.
On macOS, `pkgbuild` sets root as the owner by default, and the package keeps the modes of the build.
On Linux, the copy command sets the owner and the modes after the copy, and doesn't change the top folder, such as `/etc`.
On Windows, the copy command gives each file and folder of the build to Administrators, with the access rules that it inherits from the folder that holds it.
If a folder of the build, such as `C:\Program Files\ClaudeCode`, is already on the computer with its own rules, the copy command replaces them with the rules that the folder inherits from `C:\Program Files`.
So make sure that `C:\Program Files` follows the rule in the install step.

## Validate

Check the build on each test computer before the first prompt, so that you know that the build is in effect before a prompt goes to a model.
The checks themselves, such as `doctor`, can still send requests to the gateway, but none of them sends a prompt.
For a Windows build with `--wsl inherit`, do the checks on Windows first, and then the WSL checks at the end of this section.

Sign in to the test computer as a developer.
If you built with `--mcp-servers allowlist` or `any` and the profile has gateway MCP servers, first add those servers as the developer:

```sh
kong-harnesses profile activate work --client claude-code
```

Run [`kong-harnesses doctor`](/kong-harnesses/doctor/) to check the setup:

```sh
kong-harnesses doctor --profile work --client claude-code
```

`doctor` says that the managed settings of your organization set up the profile, and names the build ID.
It says so only when the `apiKeyHelper` that {{ site.claude_code }} takes from the managed sources on the computer is the helper of the build for the profile.
{{ site.claude_code }} merges the files in `managed-settings.d` in alphabetical order, so a file that sorts after `kong-harnesses.json` and sets its own `apiKeyHelper` replaces the helper of the build, and `doctor` then doesn't show this line.
Make sure that the build ID is the one that `fleet build` printed for this platform.
`doctor` shows a fix for each problem that it finds, and it names the setting that blocks a gateway MCP server.
Before the first request, it also says that the developer isn't signed in yet, which is expected.

Start {{ site.claude_code }}, and run `/status` before you send a prompt:

```sh
claude
```

The `Setting sources` line shows `Enterprise managed settings` with the source that {{ site.claude_code }} selected, or with the sources that it merged.
Other files in `managed-settings.d` and other policies give the same labels, so the label alone doesn't confirm the fleet build.
The build ID alone shows only the settings that `doctor` finds, not the source that {{ site.claude_code }} selected.
So check both: the build ID from `doctor`, and a label that can carry the build.
For a file build, that is `(drop-ins)` or `(file + drop-ins)`.
For an MDM build, that is `(plist)` or `(HKLM)`, or a list that starts with one of them and ends with `, merged`.
Together, the two checks confirm that the build is on the computer and that {{ site.claude_code }} applies its source.
If the line doesn't show `Enterprise managed settings`, no managed source delivers a policy key, so the build isn't in effect.
Check that each file of the build is at its path in [Check what the build holds](#check-what-the-build-holds).
For an MDM build, also check that the policy holds the settings of the build, not only control keys such as `managedSourcesBehavior`.
Then deploy the build again.
The labels:

* `(drop-ins)`: a file build, with only the files in `managed-settings.d`.
  For an MDM build, this label means that the MDM policy didn't reach the computer, or that it holds only control keys, such as `managedSourcesBehavior`.
  Check the policy that you deployed, and read the `Skipped sources` line.
* `(file)`: only your `managed-settings.json`.
  The build didn't reach the computer.
  Do the same checks as for a missing `Enterprise managed settings` line, and for an MDM build, also read the `Skipped sources` line.
* `(file + drop-ins)`: a file build on computers that also have your `managed-settings.json`.
* `(plist)` on macOS or `(HKLM)` on Windows: an MDM build.
  For a file build, this label means that an MDM policy ranks above the drop-in, and {{ site.claude_code }} ignores most keys of the drop-in.
  Build with `--delivery mdm` for those computers.
* A list that ends with `, merged`: your organization sets `managedSourcesBehavior` to `merge`, and {{ site.claude_code }} merged the listed sources.
* `(remote)`, or a merged list that starts with `remote`, such as `(remote + file, merged)`: server-managed settings from the claude.ai admin console or from a Claude apps gateway rank above the build.
  Then [the `apiKeyHelper` of the build isn't in effect](https://code.claude.com/docs/en/server-managed-settings#machine-apikeyhelper-not-in-effect), also with `merge`, because {{ site.claude_code }} reads it only from the highest source.
  Find their source, and remove them there.
  If a fetch fails, a computer can keep [a cached copy of them](https://code.claude.com/docs/en/server-managed-settings#fetch-and-caching-behavior) for up to 24 hours after its last successful fetch.
* `(HKCU)`: only the `Settings` value under `HKCU\SOFTWARE\Policies\ClaudeCode`, which a developer can write.
  [No administrator document is present](https://code.claude.com/docs/en/managed-settings#present-admin-documents) on the computer, so the build isn't in effect.
  For a file build, its file in `managed-settings.d` isn't there.
  For an MDM build, the `Settings` value under `HKLM\SOFTWARE\Policies\ClaudeCode` isn't there, but the other files of the build, such as the profile, can be.
  So check both deliveries of the build: each file in [Check what the build holds](#check-what-the-build-holds), and for an MDM build, also the `HKLM` value.
  Then deploy each one that is missing.
* `(parent process)`: the app that started {{ site.claude_code }}, such as Claude Desktop, supplied the managed settings.
  When an administrator source is on the computer, {{ site.claude_code }} [ignores those settings](https://code.claude.com/docs/en/managed-settings#let-an-embedding-host-add-policy), or merges them with that source for a build with `--host-settings merge`, so this label means that the build didn't reach the computer.
  To confirm it, read the `Skipped sources` line, start `claude` from a terminal, run `/status` there, and check the build ID with `doctor`.
  If the session from the terminal doesn't show the build either, deploy the build again.
* `(helper)`: a `policyHelper` in the MDM policy or the managed settings file computes the settings, and they replace the build.
  Remove the `policyHelper`.

If {{ site.claude_code }} ignores a source, the `Skipped sources` line names it.
To list the [entries that {{ site.claude_code }} dropped](https://code.claude.com/docs/en/managed-settings#find-entries-claude-code-dropped) from the managed settings because they are invalid, also run `claude doctor`, which names the source and the field of each one.

When the build ID and the label are both correct, send a short prompt, such as `Say hello`.
On the first request, kong-harnesses opens the browser.
On Linux, this needs a desktop session with Secret Service, as the supported computers in the prerequisites describe.
Sign in with the developer's identity provider account.
If the sign-in fails, run `kong-harnesses doctor --profile work --client claude-code`, and follow the failure that it names.
Make sure that the answer comes back through the gateway without an error, as the last proof that the build is in effect.
To confirm the route, open the [Events debugger](/ai-cost-management/analytics-and-debugging/#events-debugger) of {{site.ai_cost_management}}, and find the usage event of the test user at the time of the prompt, with the model of the session.
Its `source` names the control plane of the gateway, so make sure that it is the control plane of the profile's gateway.
The test prompt doesn't show whether the hooks of the build run, so also make sure that your policy, your `managed-settings.json` and the files in `managed-settings.d` don't set `disableAllHooks` to `true`.
If one of them does, remove the key or set it to `false`.

If the profile has gateway MCP servers, run `/mcp`, and make sure that it shows each of them as connected.
If a key server isn't connected, run `kong-harnesses login --profile work`, and type its key.
`kong-harnesses doctor` names each key server without a saved key.
If a server with its own sign-in isn't connected, sign in to it from `/mcp`.
If a server is missing, look for the settings in [Choose the MCP servers](#choose-the-mcp-servers) that block it: a `managed-mcp.json`, a `deniedMcpServers` entry, an `allowedMcpServers` list in a higher managed source that doesn't allow the gateway addresses, `strictPluginOnlyCustomization`, `strictKnownMarketplaces` or `allowedMarketplaces`, or `blockedMarketplaces`.

For a Windows build with `--wsl inherit`, the Windows package doesn't install kong-harnesses in WSL, so `profile activate` and `doctor` run only on Windows.
A check on Windows doesn't test Windows interop or the CA in a WSL distribution, so also do these checks in each WSL distribution that developers use.
`doctor` doesn't run in WSL, so there the label and the test prompt are the only checks.
Start the `claude` command that is installed in the distribution, and run `/status` before you send a prompt.
Make sure that the `Setting sources` line shows `Enterprise managed settings` with a label that can carry the build, as on Windows.
If it doesn't, make sure that you built with `--wsl inherit`, and deploy the build again.
Then send a short prompt, such as `Say hello`.
The credential helper runs kong-harnesses on Windows through interop, so the session uses the developer's Windows sign-in.
A certificate error means that the distribution doesn't trust the CA of the gateway certificate, or that {{ site.claude_code }} can't read a certificate file.
To find the cause, start [`claude --debug`](https://code.claude.com/docs/en/network-config#verify-your-configuration) in the distribution.
It writes the debug log to `~/.claude/debug/` in the distribution, not to the terminal.
If {{ site.claude_code }} can't read a certificate file, the debug log shows a `Failed to read` or `Failed to load` line with the reason.
{{ site.claude_code }} in WSL doesn't load the gateway MCP servers, so `/mcp` there doesn't list them.

For a Windows build without `--wsl inherit`, make sure on each Windows computer that no administrator source turns on WSL inheritance.
The `Settings` value under `HKLM\SOFTWARE\Policies\ClaudeCode`, `C:\Program Files\ClaudeCode\managed-settings.json` and each file in `C:\Program Files\ClaudeCode\managed-settings.d` must each leave out `wslInheritsWindowsSettings` or set it to `false`.
{{ site.claude_code }} [leaves the Windows chain off](https://code.claude.com/docs/en/settings-reference#wslinheritswindowssettings) only for no key, `null`, `false` or `"false"`, and any other value turns it on.
{{ site.claude_code }} reads the key only from these sources, and the `HKCU` value doesn't turn the chain on by itself.
If one of them sets another value, build again with `--wsl inherit`, or set the key to `false` there.

Do these checks before you install on the other managed computers.

To keep the fleet on supported {{ site.claude_code }} versions or to move it to a new model, see [Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model](/kong-harnesses/maintain-a-claude-code-fleet/).
