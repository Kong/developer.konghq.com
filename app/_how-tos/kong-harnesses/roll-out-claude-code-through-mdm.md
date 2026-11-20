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
        You also need administrator rights on one managed computer to test the result.

tldr:
  q: How do I roll out {{ site.claude_code }} to every computer of my organization with kong-harnesses?
  a: |
    Sign in to the profile on your own computer, and run `kong-harnesses fleet build` for each platform.
    Deploy {{ site.claude_code }}, kong-harnesses, the gateway's CA and the files that the build writes through your MDM tool.
    Each developer then signs in as themselves on their first {{ site.claude_code }} request.

cleanup:
  inline:
    - title: Remove the fleet build
      content: |
        Run `fleet remove` with the record file of the build.
        Replace each placeholder with the value for your deployment.

        For a file build, `fleet remove` lists the files to delete from each managed computer:

        ```sh
        kong-harnesses fleet remove --record fleet-macos/kong-harnesses-fleet-BUILD_ID.json
        ```

        For an MDM build, also pass the policy that the computers get now with `--policy`, and a new or empty folder with `--output-dir`:

        ```sh
        kong-harnesses fleet remove --record fleet-macos-mdm/kong-harnesses-fleet-BUILD_ID.json --policy com.anthropic.claudecode.plist --output-dir fleet-macos-removed
        ```

        `fleet remove` writes the policy without the settings of the build under `mdm` in the output folder.
        A value that the build replaced gets your earlier value back.
        Deploy that policy in place of the current one, and delete the files that `fleet remove` lists.
        If no other settings are left, `fleet remove` tells you to remove the policy instead.

        For a build with `--mcp-servers exclusive`, also pass the `managed-mcp.json` that the computers have now with `--mcp-config`.
        `fleet remove` writes what is left of it under `root` in the output folder, or lists `managed-mcp.json` among the files to delete.
---

With `kong-harnesses fleet build`, you turn a kong-harnesses profile into [{{ site.claude_code }} managed settings](https://code.claude.com/docs/en/managed-settings) that your mobile device management (MDM) tool deploys to every managed computer.
Developers don't install, import or edit anything.
Each developer signs in as themselves, in the browser, on their first {{ site.claude_code }} request, and kong-harnesses renews the sign-in by itself.

In this guide, you build the managed settings for each platform, check what they hold, choose how they reach the computers, and test them on one managed computer.

## Sign in on your own computer

In the Anthropic API mode, `fleet build` reads the model list of the gateway with your own sign-in, and stops when it can't read the list.
In another provider mode, it uses the models of the profile.
Sign in to the profile first:

```sh
kong-harnesses login --profile work
```

## Build the managed settings

Run `fleet build` once for each platform of your managed computers.
`--platform` names the platform of the managed computers, so you can build for every platform on the same computer.
Set `--executable` to the path where the kong-harnesses package installs the binary on the managed computers.
The filename must be `kong-harnesses`, or `kong-harnesses.exe` on Windows.

Each build needs its own output folder, and the folder must be new or empty.
This guide uses one folder for each platform:

{% navtabs "fleet-build" %}
{% navtab "macOS" %}

```sh
kong-harnesses fleet build \
  --profile work \
  --platform macos \
  --executable /usr/local/bin/kong-harnesses \
  --output-dir fleet-macos
```

{% endnavtab %}
{% navtab "Linux" %}

```sh
kong-harnesses fleet build \
  --profile work \
  --platform linux \
  --executable /usr/bin/kong-harnesses \
  --output-dir fleet-linux
```

{% endnavtab %}
{% navtab "Windows" %}

```powershell
kong-harnesses fleet build --profile work --platform windows --executable 'C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe' --output-dir fleet-windows
```

{% endnavtab %}
{% endnavtabs %}

`fleet build` writes the files that each computer needs under `root` in the output folder, at the path that each file takes on the computer.
It prints what the settings hold and how to install them.

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
  - title: MCP servers, with `--mcp-servers exclusive`
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

The managed settings hold what `kong-harnesses profile activate` writes for one developer, for every account on the computer:

* The credential helper, `kong-harnesses credential --profile work`, at the path of `--executable`.
  The settings hold no credential.
* The models of the gateway.
  In the Anthropic API mode, {{ site.claude_code }} also asks the gateway for its model list.
  A model that the gateway adds later shows in `/model` with no new build when its ID contains `claude` or `anthropic`.
  Another new model needs a new build.
  In another provider mode, the models come from the profile, or from `--model`.
* The gateway prices of the models for `/cost`, when the gateway or the profile states them.
* The {{ site.claude_code }} features that the profile turns off behind the gateway.
* A lock to the gateway.
  {{ site.claude_code }} refuses every provider but the gateway, and ignores another provider mode, a credential or custom headers that a developer sets in the shell or in their own settings.
  A session that Claude Desktop starts is the exception, because {{ site.claude_code }} then takes environment variables from the environment that Claude Desktop builds.
* A lock on MCP servers.
  {{ site.claude_code }} loads only the servers that your own managed settings provide or allow, the gateway MCP servers of the profile, and the servers that you list with `--mcp-url` or `--mcp-command`.
  It stops loading the other servers that developers added, and kong-harnesses tells developers which servers {{ site.claude_code }} doesn't load when a session starts.
* A build ID in `env.KONG_HARNESSES_FLEET_BUILD`, so a support report from a developer names the build that their computer has.

The MCP lock lets in the gateway MCP servers of the profile, but it doesn't add them to {{ site.claude_code }}.
When the profile has gateway MCP servers, `fleet build` asks you to choose with `--mcp-servers`:

* `--mcp-servers exclusive` gives every developer the gateway MCP servers.
  The build writes the servers to `managed-mcp.json`, and {{ site.claude_code }} loads only the servers in that file.
  To add your own servers to that file, pass your current `managed-mcp.json` with `--mcp-config`.
* `--mcp-servers allowlist` sets the lock and adds no servers.
  A developer gets the gateway MCP servers only after they run `kong-harnesses profile activate`.
* `--mcp-servers any` leaves MCP servers to each developer.
  A lock that your own managed settings set still applies.

The profile becomes a machine-wide profile on each computer.
kong-harnesses uses it before a developer's own profile with the same name, and developers can't change it.
kong-harnesses uses the file only when no account but an administrator can change the file and its folders.
Otherwise, it refuses the profile, because another account could send every developer's sign-in to an identity provider that it controls.

`fleet build` also writes a record file, `kong-harnesses-fleet-BUILD_ID.json`, in the output folder, outside `root`.
`BUILD_ID` is the build ID that `fleet build` prints.
Keep the record with your policy.
You need it to update the build and to remove it, and you can't create it again.

## Choose how the settings reach the computers

{{ site.claude_code }} can get managed settings from several sources on one computer.
By default, it uses only the highest of these sources:

1. Server-managed settings from the claude.ai admin console.
1. An MDM policy: the `com.anthropic.claudecode` preference domain on macOS, or the `Settings` value under `HKLM\SOFTWARE\Policies\ClaudeCode` on Windows.
1. The managed settings file, `managed-settings.json`, with the files in its `managed-settings.d` folder.

By default, `fleet build` writes its settings as a file in `managed-settings.d`.
{{ site.claude_code }} merges that file over your own `managed-settings.json`.
The keys that the build doesn't set stay as your file sets them, lists combine, and a single value of the build replaces your value.
The build sets `ANTHROPIC_CUSTOM_HEADERS`, and its value replaces the one in your `managed-settings.json`.
If your `managed-settings.json` sets `ANTHROPIC_CUSTOM_HEADERS`, pass the file with `--policy managed-settings.json`, so the build keeps your headers in its value.

On a computer that also gets a {{ site.claude_code }} MDM policy, {{ site.claude_code }} ignores the file, apart from a few keys such as `env`.
For those computers, build with `--delivery mdm`, and give the policy that the computers get now with `--policy`.
On macOS, the policy is the XML plist of the Custom Settings payload for the `com.anthropic.claudecode` preference domain.
On Windows, the policy is a JSON file with the text of the `Settings` registry value.

{% navtabs "fleet-build-mdm" %}
{% navtab "macOS" %}

```sh
kong-harnesses fleet build \
  --profile work \
  --platform macos \
  --delivery mdm \
  --policy com.anthropic.claudecode.plist \
  --executable /usr/local/bin/kong-harnesses \
  --output-dir fleet-macos-mdm
```

{% endnavtab %}
{% navtab "Windows" %}

```powershell
kong-harnesses fleet build --profile work --platform windows --delivery mdm --policy Settings.json --executable 'C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe' --output-dir fleet-windows-mdm
```

{% endnavtab %}
{% endnavtabs %}

With `--delivery mdm`, the build writes no managed settings file under `root`.
It writes the policy with your keys and its own settings under `mdm` in the output folder.
On macOS, the policy is `com.anthropic.claudecode.plist`, for a Custom Settings payload.
On Windows, the policy is `Settings.json`, with the line that goes in the `Settings` registry value.
Deploy that policy in place of the {{ site.claude_code }} policy that the computers get now.
If the computers have the managed settings file of an earlier file build, delete it, because {{ site.claude_code }} still merges its `env`.

`fleet build` refuses a policy that would stop {{ site.claude_code }} from reaching the gateway, and names the value.
It lists each of your values that it changes.
Linux has no MDM policy, so on Linux the settings always go in a file.

If you keep {{ site.claude_code }} policy in the claude.ai admin console, move it into your MDM policy or your `managed-settings.json`.
In this rollout, {{ site.claude_code }} doesn't fetch the server-managed settings, because its credential comes from the credential helper and its requests go through the gateway.

## Install on the managed computers

With your MDM tool, install the following on each managed computer:

1. {{ site.claude_code }}, at a version that Kong supports.
   `fleet build` doesn't install it.
   To install it, see [Set up {{ site.claude_code }}](https://code.claude.com/docs/en/setup).
   An older {{ site.claude_code }} doesn't refuse every other provider.
   To find the supported versions and hold the fleet to them, see [Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model](/kong-harnesses/maintain-a-claude-code-fleet/).
1. The kong-harnesses package, at the path of `--executable`.
   To install kong-harnesses, see the [kong-harnesses page](/kong-harnesses/).
1. The CA of the gateway in the system trust store, if the gateway certificate comes from a private CA.
   The build installs no CA.
1. The files under `root` in the output folder, with their paths, as an administrator.
   On macOS and Linux, root must own each file and every folder above it, and no group or other account can write to them.
   On Windows, only SYSTEM, Administrators or TrustedInstaller can own or write to each file and every folder up to `C:\Program Files`, and no link can be on the path.
1. With `--delivery mdm`, the policy under `mdm` in the output folder.

`fleet build` prints the command that packages or copies the files for the platform.
For example, on macOS, put the files in one package with `pkgbuild`.
Replace each placeholder with the value for your deployment:

```sh
pkgbuild --root fleet-macos/root --identifier PACKAGE_IDENTIFIER --version PACKAGE_VERSION kong-harnesses-fleet.pkg
```

The build sets every folder to mode 755 and every file to mode 644, so each account on the computer can read them.
A macOS package installs the files as root.

## Validate

On a managed computer, sign in to the computer as a developer and start {{ site.claude_code }}:

```sh
claude
```

On the first request, kong-harnesses opens the browser.
Sign in with your identity provider account.

In {{ site.claude_code }}, run `/status`.
The `Setting sources` line shows `Enterprise managed settings` with the source that {{ site.claude_code }} uses: `(drop-ins)` or `(file + drop-ins)` for a file build, or `(plist)` or `(HKLM)` for an MDM build.
If {{ site.claude_code }} ignores a source, the `Skipped sources` line names it.

Run `kong-harnesses doctor` to check the setup:

```sh
kong-harnesses doctor --profile work --client claude-code
```

`doctor` says that the managed settings of your organization set up the profile, and names the build.
It shows a fix for each problem that it finds.

To keep the fleet on supported {{ site.claude_code }} versions or to move it to a new model, see [Keep a {{ site.claude_code }} fleet on tested versions and move it to a new model](/kong-harnesses/maintain-a-claude-code-fleet/).
