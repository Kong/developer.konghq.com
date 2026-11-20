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
  inline:
    - title: A kong-harnesses profile
      content: |
        Create a kong-harnesses profile that signs developers in through your identity provider, as [Set up {{ site.claude_code }} with kong-harnesses](/ai-gateway/set-up-claude-code-with-kong-harnesses/) shows, and install it on the computer where you build the managed settings.
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
    Run `kong-harnesses fleet build` for each platform, after you sign in to the profile when its Claude provider is the Anthropic API.
    Deploy {{ site.claude_code }}, kong-harnesses, the gateway's CA and the files that the build writes through your MDM tool.
    Each developer then signs in as themselves on their first {{ site.claude_code }} request.

cleanup:
  inline:
    - title: Remove the fleet build
      content: |
        Run `kong-harnesses fleet remove` with the record file of the build, and add the flags that the removal needs:

        * For an MDM build, pass the policy that the computers get now with `--policy`.
        * For a build with `--mcp-servers exclusive`, pass the `managed-mcp.json` that the computers have now with `--mcp-config`.
        * When policy keys or your own MCP servers are left, pass a new or empty folder with `--output-dir`.
          `fleet remove` writes what is left there, and asks for the flag when it needs it.

        Replace each placeholder with the value for your deployment.
        For a file build without `--mcp-servers exclusive`, `fleet remove` lists the files to delete from each managed computer:

        ```sh
        kong-harnesses fleet remove --record fleet-macos/kong-harnesses-fleet-BUILD_ID.json
        ```

        For an MDM build with `--mcp-servers exclusive`, pass all the flags.
        Replace `POLICY_FILE` with the policy that the computers get now, and `MCP_CONFIG_FILE` with a copy of their `managed-mcp.json`:

        ```sh
        kong-harnesses fleet remove --record fleet-macos-mdm/kong-harnesses-fleet-BUILD_ID.json --policy POLICY_FILE --mcp-config MCP_CONFIG_FILE --output-dir fleet-macos-removed
        ```

        When keys of your own policy are left, `fleet remove` writes the policy without the settings of the build under `mdm` in the output folder.
        A value that the build replaced gets your earlier value back, if the value of the build still applies.
        A value that you changed after the build stays as you set it.
        If you set a value after the build, and your value is the same as the value of the build, `fleet remove` takes it out too, because it can't tell the two apart.
        `fleet remove` lists each value that it takes out or gives back, so check that list before you deploy the policy.
        Deploy that policy in place of the current one.
        If no other settings are left, `fleet remove` tells you to remove the policy instead.

        When your own servers are left in `managed-mcp.json`, `fleet remove` writes the file under `root` in the output folder.
        `fleet remove` keeps a server whose definition changed after the build, even when it has the name of a gateway MCP server, and names each one that it keeps.
        Remove each kept server that still points to the gateway from the file before you install it.
        Install that `managed-mcp.json` in place of the one that the computers have.
        When no server is left, `fleet remove` lists `managed-mcp.json` among the files to delete.

        Then delete the files that `fleet remove` lists from each computer, as an administrator.
---

With `kong-harnesses fleet build`, you turn a kong-harnesses profile into [{{ site.claude_code }} managed settings](https://code.claude.com/docs/en/managed-settings) that your mobile device management (MDM) tool deploys to every managed computer.
Developers don't install, import or edit anything, unless you build with `--mcp-servers allowlist` or `any` and the profile has gateway MCP servers.
Then each developer runs `profile activate` to get those servers, as [Choose the MCP servers](#choose-the-mcp-servers) describes.
Each developer signs in as themselves, in the browser, on their first {{ site.claude_code }} request, and kong-harnesses renews the sign-in by itself.

In this guide, you choose how the settings reach the computers and which MCP servers they allow, build the managed settings for each platform, check what they hold, and test them on one computer for each platform before the rest of the fleet.

## Sign in on your own computer

When the Claude provider of the profile is the Anthropic API, `fleet build` reads the model list of the gateway with your own sign-in, and refuses to build when it can't read the list.
So the computer where you run `fleet build` must reach the gateway.
For that provider, sign in to the profile first with [`kong-harnesses login`](/kong-harnesses/login/):

```sh
kong-harnesses login --profile work
```

For another Claude provider, such as Amazon Bedrock, `fleet build` uses only the models of the profile, doesn't read the model list of the gateway and doesn't need a sign-in.

## Choose how the settings reach the computers

{{ site.claude_code }} can get managed settings from several sources on one computer.
These are the administrator sources.
By default, it takes most keys from only the highest of these sources that has a policy key.
It reads [a few keys, such as `env`, from every source](https://code.claude.com/docs/en/managed-settings#keys-read-from-every-admin-source).
The sources, from highest to lowest:

1. Remote settings: server-managed settings from the claude.ai admin console, or from a Claude apps gateway.
1. An MDM policy: the `com.anthropic.claudecode` preference domain on macOS, or the `Settings` value under `HKLM\SOFTWARE\Policies\ClaudeCode` on Windows.
1. The managed settings file, `managed-settings.json`, with the files in its `managed-settings.d` folder.

On Windows, a developer can also write the `Settings` value under `HKCU\SOFTWARE\Policies\ClaudeCode`.
{{ site.claude_code }} uses that value only when no administrator source is on the computer, and no app that starts {{ site.claude_code }}, such as Claude Desktop, passes a setting that restricts Claude.

By default, `fleet build` writes its settings as a file in `managed-settings.d`.
This is a file build.
{{ site.claude_code }} merges that file over your own `managed-settings.json`.
The keys that the build doesn't set stay as your file sets them, lists combine, and a single value of the build replaces your value.
A value in your file that the build doesn't set, such as `forceLoginMethod`, or a list entry, such as one in `allowedProviders`, can still send {{ site.claude_code }} around the gateway.
The build also sets `ANTHROPIC_CUSTOM_HEADERS`, so its value replaces the one in your `managed-settings.json`.
A file build needs `--policy` or `--no-policy`.
If the computers have a `managed-settings.json`, pass a copy of it with `--policy`.
The build then keeps your headers in its value.
If the computers don't get a {{ site.claude_code }} policy of your own, such as a `managed-settings.json`, pass `--no-policy`.
For a file build, `--policy` takes only a `managed-settings.json`, not an MDM policy.

{{ site.claude_code }} merges the files in `managed-settings.d` in alphabetical order, and a later file replaces a single value of an earlier file.
`--policy` checks only `managed-settings.json`, so check each of your own files in `managed-settings.d`.
A file whose name sorts after `kong-harnesses.json` in alphabetical order must not set a key that the build sets, such as `apiKeyHelper` or a variable in `env`.
A file whose name sorts before `kong-harnesses.json` loses each value that the build sets, such as the headers in `ANTHROPIC_CUSTOM_HEADERS`, and `fleet build` doesn't tell you.
Move such headers into your `managed-settings.json`, and pass a copy of it with `--policy`, so that the build keeps them.
No file, in any order, may set `policyHelper`, because the settings that a policy helper computes replace all the other managed settings.
Also make sure that no file adds an `allowedProviders` entry, because lists combine from every file.
No file may set `forceLoginMethod` either, because the build doesn't set it, so a value of it in any file applies.

By default, on a computer that also gets a {{ site.claude_code }} MDM policy, {{ site.claude_code }} takes most keys from the MDM policy and ignores them in the file.
So those computers need an MDM build, because the credential helper and the hooks of a file build don't apply there.
{{ site.claude_code }} still reads [a few keys from every administrator source](https://code.claude.com/docs/en/managed-settings#keys-read-from-every-admin-source), such as `env`.
One of them is the MCP lock that `--mcp-servers allowlist` sets, so the lock and its server list can still apply from the file.
But while the lock is on, {{ site.claude_code }} takes the server list from the highest administrator source that sets one.
So if the MDM policy on the computers sets its own `allowedMcpServers` list, that list replaces the list of the build.
If that list doesn't allow the addresses of the gateway MCP servers, {{ site.claude_code }} doesn't load them.
For those computers, build with `--delivery mdm`.
This is an MDM build.
If the computers get a {{ site.claude_code }} policy now, pass it with `--policy`.
If they don't get a {{ site.claude_code }} policy of your own, pass `--no-policy`.
On macOS, the policy is the XML property list of the Custom Settings payload for the `com.anthropic.claudecode` preference domain.
On Windows, the policy is a JSON file with exactly the text of the `Settings` registry value, not a `.reg` export.
If your organization sets `managedSourcesBehavior` to `merge`, {{ site.claude_code }} applies the file and the MDM policy together.
Then also check your `managed-settings.json` and the files in `managed-settings.d`, because {{ site.claude_code }} merges them with the MDM policy.
A lower source [adds its list entries](https://code.claude.com/docs/en/managed-settings#compose-every-managed-source), such as `permissions.allow` rules and `hooks`, and supplies each key that the MDM policy leaves unset, such as `model`.
Remove each value that conflicts with the build, and each list entry or key that you don't want on the computers.
Login keys, such as `forceLoginMethod`, still come only from the highest MDM policy or file with a policy key.
Linux doesn't have an MDM policy, so on Linux the settings always go in a file.

`fleet build` refuses a policy that would stop {{ site.claude_code }} from reaching the gateway, and names the value.
It lists each of your values that it changes.

If you keep {{ site.claude_code }} policy in the claude.ai admin console or on a Claude apps gateway, move it into your MDM policy or your `managed-settings.json`.
Then remove it from its source.
An API key that the build's `apiKeyHelper` returns doesn't start the fetch of server-managed settings.
But on a computer where a developer kept a claude.ai login of your organization, {{ site.claude_code }} can still fetch them.
The server-managed settings then rank above the build, and the build's `apiKeyHelper` isn't in effect.

## Choose the MCP servers

`--mcp-servers` sets which MCP servers {{ site.claude_code }} loads on the managed computers.
When the profile has gateway MCP servers, `fleet build` needs this flag.
When the profile doesn't have gateway MCP servers, use `allowlist`, the default, or `any`.
When the profile has gateway MCP servers, a `managed-mcp.json` on the computers or some of your own managed settings can leave `exclusive` as the only mode that loads them.

* `--mcp-servers exclusive` gives every developer the gateway MCP servers of the profile.
  It needs a profile with at least one gateway MCP server.
  The build writes the servers to `managed-mcp.json` under `root`, also for an MDM build.
  {{ site.claude_code }} then loads only the servers in that file and the few others that the [managed MCP docs](https://code.claude.com/docs/en/managed-mcp#exclusive-control-with-managed-mcp-json) list, such as the servers that `managedMcpServers` provides.
  It loads no server that a developer, a project or a plugin adds.
  To keep your own servers in that file, pass the `managed-mcp.json` that the computers have with `--mcp-config`.
  This mode doesn't take `--mcp-url` or `--mcp-command`.
* `--mcp-servers allowlist`, the default, locks {{ site.claude_code }} to the servers that your own managed settings provide or allow, the gateway MCP servers of the profile, and the servers that you list with `--mcp-url` or `--mcp-command`.
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
  {{ site.claude_code }} then loads only the servers in that file and the few others that the [managed MCP docs](https://code.claude.com/docs/en/managed-mcp#exclusive-control-with-managed-mcp-json) list, and not the servers of the plugin that `profile activate` adds.
* Your own managed settings set `strictPluginOnlyCustomization` to `true`, or to a list with one or more kinds, such as `mcp`.
* Your own managed settings set `strictKnownMarketplaces`, or [its alias](https://code.claude.com/docs/en/settings-reference#marketplace-key-aliases) `allowedMarketplaces`, without a `{"source": "skills-dir"}` entry, or `blockedMarketplaces` with one.

When the policy that you pass with `--policy` sets one of these values, `fleet build` refuses `allowlist` and `any` for a profile with gateway MCP servers.
For a value that only the computers have, such as a `managed-mcp.json`, check the computers yourself.

In each case, {{ site.claude_code }} [skips the plugin](https://code.claude.com/docs/en/plugins/loading#skills-directory-plugins-blocked-by-managed-settings) that `profile activate` adds, or the servers in it.
If the profile has gateway MCP servers, use `exclusive`, and if the computers have a `managed-mcp.json`, pass it with `--mcp-config`.
`exclusive` doesn't work with `--wsl inherit`, which [Build the managed settings](#build-the-managed-settings) describes.
For Windows computers that need {{ site.claude_code }} in WSL, remove the setting or the `managed-mcp.json` that blocks the plugin, and use `allowlist` or `any`.
Otherwise, use `exclusive`, and leave out `--wsl inherit`.

With `exclusive` or `allowlist`, {{ site.claude_code }} stops loading the other servers that developers added, and when a session starts, kong-harnesses names each server that the developer added and that {{ site.claude_code }} doesn't load.

In every mode, a `deniedMcpServers` entry blocks each server that it matches, also a gateway MCP server.
{{ site.claude_code }} combines the entries from all settings, also from the settings of a developer.
Make sure that your own managed settings don't deny a gateway MCP server.

## Build the managed settings

Run `fleet build` once for each platform of your managed computers.
`--platform` names the platform of the managed computers, so you can build for every platform on the same computer.
Set `--executable` to the path where the kong-harnesses package installs the binary on the managed computers.
The filename must be `kong-harnesses`, or `kong-harnesses.exe` on Windows.
Each build needs its own output folder, and the folder must be new or empty.
This guide uses one folder for each build.

Replace each placeholder with the value for your deployment:

* Replace `MCP_MODE` with the mode that you chose in [Choose the MCP servers](#choose-the-mcp-servers): `exclusive`, `allowlist` or `any`.
  With `exclusive`, if the computers have a `managed-mcp.json`, also add `--mcp-config` with a copy of that file.
* For a file build, replace `POLICY_FILE` with the path of your copy of `managed-settings.json`.
  If the computers don't get a {{ site.claude_code }} policy of your own, such as a `managed-settings.json`, replace `--policy POLICY_FILE` with `--no-policy`.
* For an MDM build, replace `POLICY_FILE` with the path of your current policy, such as `com.anthropic.claudecode.plist` on macOS or `Settings.json` on Windows.
  If the computers don't get a {{ site.claude_code }} policy of your own now, replace `--policy POLICY_FILE` with `--no-policy`.

Claude Desktop, an IDE extension or an Agent SDK app can start {{ site.claude_code }} and pass settings of its own, the host settings.
When the computer has managed settings, {{ site.claude_code }} ignores the host settings by default.
To [merge them](https://code.claude.com/docs/en/managed-settings#let-an-embedding-host-add-policy), add `--host-settings merge`, which sets `parentSettingsBehavior` to `merge` and replaces the value that your own policy sets.
{{ site.claude_code }} reads this key only from the highest managed source on the computer, so the build must be that source.
{{ site.claude_code }} then keeps only the host settings that restrict what Claude can do, with two exceptions.
The permission allow rules of the host still apply, unless your own managed settings set `allowManagedPermissionRulesOnly`.
The sandbox allowlists of the host still apply, unless your own managed settings set `sandbox.network.allowManagedDomainsOnly` for domains and `sandbox.filesystem.allowManagedReadPathsOnly` for read paths.
[Restrict parent settings](https://code.claude.com/docs/en/claude-apps-gateway#restrict-parent-settings) lists all the locks.

The Windows examples set up {{ site.claude_code }} on Windows itself.
By default, {{ site.claude_code }} in WSL on those computers doesn't use the settings.
To give it the same settings, add `--wsl inherit`.
If your `--policy` sets `wslInheritsWindowsSettings` to `true`, `fleet build` refuses a Windows build without `--wsl inherit`, so add the option or set the key to `false` in the policy.
This option needs Windows interop, which lets WSL run Windows programs, in each WSL distribution.
If interop is off, the credential helper tells the developer to turn it on.
This option doesn't work with `--mcp-servers exclusive`, because {{ site.claude_code }} in WSL reads `managed-mcp.json` only from `/etc/claude-code`.
With this option, `fleet build` also refuses an `--executable` path with `'`, `"`, `%` or `!`, and a `--policy` whose `env` sets `NODE_EXTRA_CA_CERTS`, `CLAUDE_CODE_CLIENT_CERT` or `CLAUDE_CODE_CLIENT_KEY`.
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
  --policy POLICY_FILE \
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
  --policy POLICY_FILE \
  --mcp-servers MCP_MODE \
  --output-dir fleet-linux
```

{% endnavtab %}
{% navtab "Windows" %}

```powershell
kong-harnesses fleet build --profile work --platform windows --executable 'C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe' --policy POLICY_FILE --mcp-servers MCP_MODE --output-dir fleet-windows
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
  --policy POLICY_FILE \
  --mcp-servers MCP_MODE \
  --output-dir fleet-macos-mdm
```

{% endnavtab %}
{% navtab "Windows" %}

```powershell
kong-harnesses fleet build --profile work --platform windows --delivery mdm --executable 'C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe' --policy POLICY_FILE --mcp-servers MCP_MODE --output-dir fleet-windows-mdm
```

{% endnavtab %}
{% endnavtabs %}

`fleet build` writes the files that each computer needs under `root` in the output folder, at the path that each file takes on the computer.
An MDM build also writes the policy with your keys and its own settings under `mdm` in the output folder.
On macOS, the policy is `com.anthropic.claudecode.plist`, for a Custom Settings payload.
On Windows, the policy is `Settings.json`, with the line that goes in the `Settings` registry value.
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

The managed settings, in the file or in the MDM policy, hold what `kong-harnesses profile activate` writes for one developer, for every account on the computer:

* The credential helper, `kong-harnesses credential --profile work`, at the path of `--executable`.
  The settings don't hold a credential.
* Hooks that run kong-harnesses at the path of `--executable`.
  When a session starts, one hook names each MCP server that the developer added and that {{ site.claude_code }} doesn't load.
  When the gateway or the profile marks a model as one that can't run WebSearch, another hook tells that model that no search ran.
* The models of the gateway.
  The settings set the default model of each Claude family, and the model of other roles such as subagents, to the models of the profile, or to the models that you name with `--model`, such as `--model MODEL_ID`.
  Each `--model` replaces the model of the family that it names, and of each role, such as subagents, that used the earlier model of that family.
  The other families and their roles keep the models of the profile.
  For a model ID that doesn't name exactly one Claude family, add the family, such as `--model opus=MODEL_ID`.
  When the Claude provider is the Anthropic API, {{ site.claude_code }} also asks the gateway for its model list.
  A model that the gateway adds later then shows in `/model` without a new build when its ID contains `claude` or `anthropic`.
  Another new model needs a new build.
  For another Claude provider, `/model` shows only the models of the build.
* The gateway prices of the models for `/cost`, when the gateway or the profile states them.
* The {{ site.claude_code }} features that the profile turns off behind the gateway.
* A lock to the gateway.
  {{ site.claude_code }} refuses every provider but the gateway, and ignores another Claude provider, a credential or custom headers that a developer sets in the shell or in their own settings.
  A session that Claude Desktop starts is the exception, because {{ site.claude_code }} then takes environment variables from the environment that Claude Desktop builds.
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
   If an earlier file build installed `managed-settings.d/kong-harnesses.json` on the computers, delete that file, because {{ site.claude_code }} still merges its `env`.

`fleet build` prints the command that packages or copies the files for the platform, with the full path of the `root` folder.
For example, on macOS, it prints a `pkgbuild` command like this one, which puts the files in one package.
Replace each placeholder with the value for your deployment, and `/PATH/TO` with the folder where you ran `fleet build`:

```sh
pkgbuild --root '/PATH/TO/fleet-macos/root' --install-location / --identifier PACKAGE_IDENTIFIER --version PACKAGE_VERSION kong-harnesses-fleet.pkg
```

The build sets every folder to mode 755 and every file to mode 644, so each account on the computer can read them.
By default, `pkgbuild` sets root as the owner of each file in the package, so the package installs the files as root.
On Linux, `fleet build` prints a copy command that creates the files as root, and sets each folder that the build writes to mode 755 and each file to mode 644.
The command doesn't change `/etc`.
On Windows, the copy command that `fleet build` prints gives each file the access rules of the folder that holds it.
If a folder of the build, such as `C:\Program Files\ClaudeCode`, is already on the computer with its own rules, the files get those rules, so make sure that each folder on the path follows the rule in the install step.

## Validate

Check the build on each test computer before the first prompt, so that you know that the build is in effect before a prompt goes to a model.
The checks themselves, such as `doctor`, can still send requests to the gateway, but none of them sends a prompt.
For a Windows build with `--wsl inherit`, also do these checks in {{ site.claude_code }} in each WSL distribution that developers use, because a check on Windows doesn't test Windows interop or the CA in the distribution.

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
Make sure that the build ID is the one that `fleet build` printed for this platform.
`doctor` shows a fix for each problem that it finds, and it names the setting that blocks a gateway MCP server.
Before the first request, it also says that the developer isn't signed in yet, which is expected.

Start {{ site.claude_code }}, and run `/status` before you send a prompt:

```sh
claude
```

The `Setting sources` line shows `Enterprise managed settings` with the source that {{ site.claude_code }} selected, or with the sources that it merged.
Other files in `managed-settings.d` and other policies give the same labels, so only the build ID from `doctor` confirms the fleet build.
If the line doesn't show `Enterprise managed settings`, no managed source delivers a policy key, so the build isn't in effect.
Check that each file of the build is at its path in [Check what the build holds](#check-what-the-build-holds).
For an MDM build, also check that the policy holds the settings of the build, not only control keys such as `managedSourcesBehavior`.
Then deploy the build again.
The labels:

* `(drop-ins)`: a file build, with only the files in `managed-settings.d`.
  For an MDM build, this label means that the MDM policy didn't reach the computer, so read the `Skipped sources` line.
* `(file)`: only your `managed-settings.json`.
  The build didn't reach the computer.
  For a file build, check that the drop-in is at the path in [Check what the build holds](#check-what-the-build-holds).
  For an MDM build, read the `Skipped sources` line, and look at the MDM policy on the computer.
  The policy must hold the settings of the build, not only control keys such as `managedSourcesBehavior`, because {{ site.claude_code }} skips a policy without a policy key.
  Then deploy the build again.
* `(file + drop-ins)`: a file build on computers that also have your `managed-settings.json`.
* `(plist)` on macOS or `(HKLM)` on Windows: an MDM build.
  For a file build, this label means that an MDM policy ranks above the drop-in, and {{ site.claude_code }} ignores most keys of the drop-in.
  Build with `--delivery mdm` for those computers.
* A list that ends with `, merged`: your organization sets `managedSourcesBehavior` to `merge`, and {{ site.claude_code }} merged the listed sources.
* `(remote)`: server-managed settings from the claude.ai admin console or from a Claude apps gateway rank above the build.
  Find their source, and remove them there.
  If a fetch fails, a computer can keep [a cached copy of them](https://code.claude.com/docs/en/server-managed-settings#fetch-and-caching-behavior) for up to 24 hours after its last successful fetch.
* `(HKCU)`: only the `Settings` value under `HKCU\SOFTWARE\Policies\ClaudeCode`, which a developer can write.
  No administrator source reached the computer, so the build isn't in effect.
  Deploy the build again.
* `(parent process)`: the app that started {{ site.claude_code }}, such as Claude Desktop, supplied the managed settings.
  {{ site.claude_code }} [ignores those settings when an administrator source is on the computer](https://code.claude.com/docs/en/managed-settings#let-an-embedding-host-add-policy), so the build didn't reach the computer.
  To confirm it, read the `Skipped sources` line, start `claude` from a terminal, run `/status` there, and check the build ID with `doctor`.
  If the session from the terminal doesn't show the build either, deploy the build again.
* `(helper)`: a `policyHelper` in the MDM policy or the managed settings file computes the settings, and they replace the build.
  Remove the `policyHelper`.

If {{ site.claude_code }} ignores a source, the `Skipped sources` line names it.
To list the entries that {{ site.claude_code }} dropped from the managed settings, also run `claude doctor`.

When the build ID and the source are correct, send a short prompt, such as `Say hello`.
On the first request, kong-harnesses opens the browser.
Sign in with the developer's identity provider account.

If the profile has gateway MCP servers, run `/mcp`, and make sure that it lists them.
If a server is missing, look for the settings in [Choose the MCP servers](#choose-the-mcp-servers) that block it: a `managed-mcp.json`, a `deniedMcpServers` entry, an `allowedMcpServers` list in the MDM policy that doesn't allow the gateway addresses, `strictPluginOnlyCustomization`, `strictKnownMarketplaces` or `allowedMarketplaces`, or `blockedMarketplaces`.

Do these checks before you install on the other managed computers.

To keep the fleet on supported {{ site.claude_code }} versions or to move it to a new model, see [Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model](/kong-harnesses/maintain-a-claude-code-fleet/).
