---
title: Roll out {{ site.claude_code }} to an organization through MDM
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
  - text: Maintain a {{ site.claude_code }} fleet
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
    - title: An MDM tool
      content: |
        You need a tool that installs a package and a configuration profile or policy on the managed computers, such as Jamf Pro on macOS, Microsoft Intune on Windows, or your configuration management tool on Linux.
        You also need administrator rights on one managed computer to test the result.

tldr:
  q: How do I roll out {{ site.claude_code }} to every computer of my organization with kong-harnesses?
  a: |
    Sign in to the profile on your own computer, and run `kong-harnesses fleet build` for each platform.
    Deploy kong-harnesses, the gateway's CA and the files that the build writes through your MDM tool.
    Each developer then signs in as themselves on their first {{ site.claude_code }} request.

cleanup:
  inline:
    - title: Remove the fleet build
      content: |
        Keep the record file that `fleet build` wrote, and run `fleet remove` with it:

        ```sh
        kong-harnesses fleet remove --record fleet/kong-harnesses-fleet-<build>.json
        ```

        `fleet remove` lists the files to delete from each managed computer.
        For a build with `--delivery mdm`, also pass the policy that the computers get now with `--policy <file>`.
        `fleet remove` then writes the policy without the settings of the build under `mdm` in the folder that you name with `--output-dir`.
---

With `kong-harnesses fleet build`, you turn a kong-harnesses profile into [{{ site.claude_code }} managed settings](https://code.claude.com/docs/en/managed-settings) that your MDM tool deploys to every managed computer.
Developers don't install, import or edit anything.
Each developer signs in as themselves, in the browser, on their first {{ site.claude_code }} request, and kong-harnesses renews the sign-in by itself.

In this guide, you build the managed settings for one platform, check what they hold, choose how they reach the computers, and test them on one managed computer.

## Sign in on your own computer

`fleet build` reads the model list of the gateway with your own sign-in, and stops when it can't read the list.
Sign in to the profile first:

```sh
kong-harnesses login --profile work
```

## Build the managed settings

Run `fleet build` once for each platform of your managed computers.
`--platform` names the platform of the managed computers, so you can build for each platform on the same computer.
Set `--executable` to the path where the kong-harnesses package installs the binary on the managed computers.
The filename must be `kong-harnesses`, or `kong-harnesses.exe` on Windows.
The output folder must be new or empty.

{% navtabs "fleet-build" %}
{% navtab "macOS" %}

```sh
kong-harnesses fleet build \
  --profile work \
  --platform macos \
  --executable /usr/local/bin/kong-harnesses \
  --output-dir fleet
```

{% endnavtab %}
{% navtab "Linux" %}

```sh
kong-harnesses fleet build \
  --profile work \
  --platform linux \
  --executable /usr/bin/kong-harnesses \
  --output-dir fleet
```

{% endnavtab %}
{% navtab "Windows" %}

```sh
kong-harnesses fleet build \
  --profile work \
  --platform windows \
  --executable 'C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe' \
  --output-dir fleet
```

{% endnavtab %}
{% endnavtabs %}

`fleet build` writes the files that each computer needs under `fleet/root`, at the path that each file takes on the computer.
It prints what the settings hold and how to install them.

## Check what the build holds

The build writes these files under `root`:

{% table %}
columns:
  - title: File
    key: file
  - title: macOS
    key: macos_path
  - title: Linux
    key: linux_path
  - title: Windows
    key: windows_path
rows:
  - file: Managed settings
    macos_path: "`/Library/Application Support/ClaudeCode/managed-settings.d/kong-harnesses.json`"
    linux_path: "`/etc/claude-code/managed-settings.d/kong-harnesses.json`"
    windows_path: "`C:\\Program Files\\ClaudeCode\\managed-settings.d\\kong-harnesses.json`"
  - file: Profile
    macos_path: "`/Library/Application Support/kong-harnesses/profiles/work.json`"
    linux_path: "`/etc/kong-harnesses/profiles/work.json`"
    windows_path: "`C:\\Program Files\\kong-harnesses\\profiles\\work.json`"
{% endtable %}

The managed settings hold what `kong-harnesses profile activate` writes for one developer, for every account on the computer:

* The credential helper, `kong-harnesses credential --profile work`, at the path of `--executable`. The settings hold no credential.
* The models of the gateway. In the Anthropic API mode, {{ site.claude_code }} also asks the gateway for its model list, so a model that the gateway adds later reaches the computers with no new build. In another provider mode, the models come from the profile.
* The gateway prices of the models for `/cost`, when the gateway or the profile states them.
* The {{ site.claude_code }} features that the profile turns off behind the gateway.
* A lock to the gateway. {{ site.claude_code }} refuses every provider but the gateway, and ignores another provider mode, a credential or custom headers that a developer sets in the shell or in their own settings.
* A lock on MCP servers. {{ site.claude_code }} loads only the gateway MCP servers of the profile, the servers that your own managed settings allow, and the servers that you list with `--mcp-url` or `--mcp-command`. It stops loading the servers that developers added, and tells them which servers it doesn't load when a session starts. To leave MCP servers to each developer, add `--mcp-servers any`.
* A build ID in `env.KONG_HARNESSES_FLEET_BUILD`, so a support report from a developer names the build that their computer has.

The profile becomes a machine-wide profile on each computer.
kong-harnesses uses it before a developer's own profile with the same name, and developers can't change it.
kong-harnesses uses the file only when no account but an administrator can change the file and its folders.
Otherwise, it refuses the profile, because another account could send every developer's sign-in to an identity provider that it controls.

`fleet build` also writes a record file, `kong-harnesses-fleet-<build>.json`, in the output folder, outside `root`.
Keep the record with your policy.
You need it to update the build and to remove it, and you can't create it again.

## Choose how the settings reach the computers

{{ site.claude_code }} can get managed settings from several sources on one computer, and by default it uses only the highest source:

1. Server-managed settings from the claude.ai admin console.
1. An MDM policy: the `com.anthropic.claudecode` preference domain on macOS, or the `Settings` value under `HKLM\SOFTWARE\Policies\ClaudeCode` on Windows.
1. The managed settings file, `managed-settings.json`, with the files in its `managed-settings.d` folder.

By default, `fleet build` writes its settings as a file in `managed-settings.d`.
{{ site.claude_code }} merges that file over your own `managed-settings.json`, so your file stays in force.
On a computer that also gets a {{ site.claude_code }} MDM policy, {{ site.claude_code }} ignores the file, apart from a few keys such as `env`.
For those computers, build with `--delivery mdm`, and give the policy that the computers get now with `--policy`:

{% navtabs "fleet-build-mdm" %}
{% navtab "macOS" %}

```sh
kong-harnesses fleet build \
  --profile work \
  --platform macos \
  --delivery mdm \
  --policy com.anthropic.claudecode.plist \
  --executable /usr/local/bin/kong-harnesses \
  --output-dir fleet
```

{% endnavtab %}
{% navtab "Windows" %}

```sh
kong-harnesses fleet build \
  --profile work \
  --platform windows \
  --delivery mdm \
  --policy Settings.json \
  --executable 'C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe' \
  --output-dir fleet
```

{% endnavtab %}
{% endnavtabs %}

The build then writes the policy with your keys and its own settings under `fleet/mdm`, as `com.anthropic.claudecode.plist` on macOS or as `Settings.json`, the JSON of the registry value, on Windows.
Deploy that policy in place of the {{ site.claude_code }} policy that the computers get now.
`fleet build` refuses a policy that would stop {{ site.claude_code }} from reaching the gateway, and names the value.
It lists each of your values that it changes.
Linux has no MDM policy, so on Linux the settings always go in a file.

If you keep {{ site.claude_code }} policy in the claude.ai admin console, move it into your MDM policy or your `managed-settings.json`.
{{ site.claude_code }} fetches the server-managed settings only for a developer who signs in to Anthropic.
Behind the gateway, it doesn't fetch them.

## Install on the managed computers

With your MDM tool, install the following on each managed computer:

1. The kong-harnesses package, at the path of `--executable`. To install kong-harnesses, see the [kong-harnesses page](/kong-harnesses/).
1. The CA of the gateway in the system trust store, if the gateway certificate comes from a private CA. The build installs no CA.
1. The files under `fleet/root`, with their paths, as an administrator.
1. With `--delivery mdm`, the policy under `fleet/mdm`.

`fleet build` prints the command that packages or copies the files for the platform.
For example, on macOS, put the files in one package with `pkgbuild`:

```sh
pkgbuild --root fleet/root --identifier <identifier> --version <version> kong-harnesses-fleet.pkg
```

The build sets every folder to mode 755 and every file to mode 644, so each account on the computer can read them.

## Validate

On a managed computer, sign in to the computer as a developer and start {{ site.claude_code }}:

```sh
claude
```

On the first request, kong-harnesses opens the browser.
Sign in with your identity provider account.

In {{ site.claude_code }}, run `/status`.
The `Setting sources` line shows `Enterprise managed settings` with the source that {{ site.claude_code }} uses: `(drop-ins)` or `(file + drop-ins)` for a file build, or `(plist)` or `(HKLM)` for an MDM build.
If {{ site.claude_code }} uses a different source, the `Skipped sources` line names the one that it ignores.

Run `kong-harnesses doctor` to check the setup:

```sh
kong-harnesses doctor --profile work --client claude-code
```

`doctor` says that the managed settings of your organization set up the profile, and names the build.
It shows a fix for each problem that it finds.

To keep the fleet on supported {{ site.claude_code }} versions or to move it to a new model, see [Maintain a {{ site.claude_code }} fleet](/kong-harnesses/maintain-a-claude-code-fleet/).
