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

{% navtabs "fleet-rebuild" %}
{% navtab "macOS" %}

For `POLICY_FILE`, use the MDM policy (`com.anthropic.claudecode.plist`) for an MDM build, or `/Library/Application Support/ClaudeCode/managed-settings.json` from a managed computer for a file build.
If the computers don't have that file, replace `--policy 'POLICY_FILE'` with `--no-policy`.

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

Linux builds use file delivery, so the command has no `--delivery` option.
For `POLICY_FILE`, use `/etc/claude-code/managed-settings.json` from a managed computer.
If the computers don't have that file, replace `--policy 'POLICY_FILE'` with `--no-policy`.

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
The earlier build can have used options that you keep, such as `--mcp-servers`, `--mcp-url`, `--host-settings`, `--wsl`, or `--executable` with another path.
Add the flag from the error to the command, and run it again with a new or empty `NEW_FOLDER`.
To drop an option of the earlier build instead, see [Keep or revert recorded flags](/kong-harnesses/fleet-build-options/#keep-or-revert-recorded-flags).
