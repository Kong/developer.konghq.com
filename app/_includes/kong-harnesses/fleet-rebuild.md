If the profile uses the Anthropic API provider, sign in first, so that `fleet build` can read the model list of your gateway:

```sh
kong-harnesses login --profile PROFILE_NAME
```

kong-harnesses opens your browser to sign in with Okta.
Replace `PROFILE_NAME` with the `name` value in the record file of the build that your computers have now.

Run the rebuild on the computer where you made the earlier build, once for each policy group.
A policy group is a set of computers with the same platform, delivery, deployed build, and policy.

Replace these placeholders in the command:

* `RECORD_FILE`: The record file of the build that your computers have now.
* `PROFILE_NAME`: The `name` value in the record file.
* `DELIVERY`: The `delivery` value in the record file, `file` or `mdm`.
* `POLICY_FILE`: The policy that your computers get now. The tab for your platform names it.
* `NEW_FOLDER`: A new or empty folder for the new build, without spaces in its name.
* `MCP_CONFIG_FILE`: For an `exclusive` MCP build, the `managed-mcp.json` that your computers have now. The tab for your platform names it.

{% navtabs "fleet-rebuild" %}
{% navtab "macOS" %}

For `POLICY_FILE`, use the MDM policy (`com.anthropic.claudecode.plist`) for an MDM build, or `/Library/Application Support/ClaudeCode/managed-settings.json` from a managed computer for a file build.
If the computers don't have that file, replace `--policy 'POLICY_FILE'` with `--no-policy`.

The command passes `/usr/local/bin/kong-harnesses`, where the installer package installs kong-harnesses.
If the earlier build used another `--executable` path, copy that argument with its quotes.

For an `exclusive` MCP build, use `/Library/Application Support/ClaudeCode/managed-mcp.json` from a managed computer for `MCP_CONFIG_FILE`.
Add `--mcp-config 'MCP_CONFIG_FILE'` to the command, also when the earlier build didn't use `--mcp-config`.

```sh
kong-harnesses fleet build \
  --profile PROFILE_NAME \
  --platform macos \
  --delivery DELIVERY \
  --executable /usr/local/bin/kong-harnesses \
  --policy 'POLICY_FILE' \
  --record 'RECORD_FILE' \
  {{ include.change }} \
  --output-dir NEW_FOLDER
```

{% endnavtab %}
{% navtab "Linux" %}

Linux builds use file delivery, so the command doesn't have a `--delivery` option.
For `POLICY_FILE`, use `/etc/claude-code/managed-settings.json` from a managed computer.
If the computers don't have that file, replace `--policy 'POLICY_FILE'` with `--no-policy`.

The command passes `/usr/bin/kong-harnesses`, where the Linux packages install kong-harnesses.
If the earlier build used another `--executable` path, copy that argument with its quotes.

For an `exclusive` MCP build, use `/etc/claude-code/managed-mcp.json` from a managed computer for `MCP_CONFIG_FILE`.
Add `--mcp-config 'MCP_CONFIG_FILE'` to the command, also when the earlier build didn't use `--mcp-config`.

```sh
kong-harnesses fleet build \
  --profile PROFILE_NAME \
  --platform linux \
  --executable /usr/bin/kong-harnesses \
  --policy 'POLICY_FILE' \
  --record 'RECORD_FILE' \
  {{ include.change }} \
  --output-dir NEW_FOLDER
```

{% endnavtab %}
{% navtab "Windows" %}

For `POLICY_FILE`, use the MDM policy (`Settings.json`) for an MDM build, or `C:\Program Files\ClaudeCode\managed-settings.json` from a managed computer for a file build.
If the computers don't have that file, replace `--policy 'POLICY_FILE'` with `--no-policy`.

The command passes `C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe`, where the MSI installer installs kong-harnesses.
If the earlier build used another `--executable` path, copy that argument with its quotes.

For an `exclusive` MCP build, use `C:\Program Files\ClaudeCode\managed-mcp.json` from a managed computer for `MCP_CONFIG_FILE`.
Add `--mcp-config 'MCP_CONFIG_FILE'` to the command, also when the earlier build didn't use `--mcp-config`.

```powershell
kong-harnesses fleet build `
  --profile PROFILE_NAME `
  --platform windows `
  --delivery DELIVERY `
  --executable 'C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe' `
  --policy 'POLICY_FILE' `
  --record 'RECORD_FILE' `
  {{ include.change }} `
  --output-dir NEW_FOLDER
```

{% endnavtab %}
{% endnavtabs %}

`fleet build` writes the build to `NEW_FOLDER` and prints the build ID and the path of the new record file.

If the build refuses to run, it names the flag to add.
The earlier build can have used options that you keep, such as `--mcp-servers`, `--mcp-url`, `--host-settings`, or `--wsl`.
Add the flag from the error to the command, and run it again with a new or empty `NEW_FOLDER`.
