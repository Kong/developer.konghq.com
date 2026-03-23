---
name: kong-curl-to-http-request
version: 1.0.0
description: Find standalone curl commands in Kong documentation files and convert them to {% http_request %} Liquid blocks. Use when reviewing or editing how-to guides that contain raw curl commands in code blocks.
argument-hint: <file-or-directory>
context: fork
allowed-tools: Read, Grep, Glob, Edit, Bash(grep *)
---

You are a Kong documentation formatter. Your job is to find raw `curl` commands in documentation files and convert them to `{% http_request %}` Liquid blocks.

## Inputs

`$ARGUMENTS` is a file or directory path. If empty, scan `app/_how-tos/`.

## Step 1: Find files with curl commands

Use `grep -rl "curl " <target-path> --include="*.md" --exclude-dir=app/.repos --exclude-dir=mesh_policies --exclude-dir=app/_references` to get candidate files.

## Step 2: Identify convertible curl commands

Read each file. Find `curl` commands inside fenced bash code blocks (` ```bash `) that are **not** already inside a `{% http_request %}`, `{% control_plane_request %}`, or `{% konnect_api_request %}` block.

Skip curls that:
- Are inside a `{% http_request %}`, `{% control_plane_request %}`, or `{% konnect_api_request %}` block already
- Are inside a `{% validation %}` block
- Use flags the tag doesn't support (e.g. `--resolve`, `--unix-socket`, `-o /dev/null`)
- Have no URL (e.g. piped curl snippets, incomplete examples)

Silently drop these flags — they have no equivalent in the tag and should not block conversion:
- `-s` / `--silent`
- `-v` / `--verbose`
- `-i` / `--include`
- `--no-progress-meter`
- `--fail-with-body`
- `-L` / `--location`

## Step 3: Parse the curl command into YAML fields

Map curl flags to `{% http_request %}` YAML fields:

| curl flag | YAML field |
|-----------|------------|
| `-X METHOD` or `--request METHOD` | `method` |
| `-H "Header: value"` | `headers` (list) |
| `--json '{...}'` or `-d '{...}'` or `--data '{...}'` | `body` |
| `-u user:pass` | `user` |
| `-k` or `--insecure` | `insecure: true` |
| `\| jq ...` | `jq` |
| The URL (positional arg) | `url` |

Rules:
- `url` is required. Strip protocol prefix `http://` or `https://` — the template adds it based on context. Exception: if the URL contains `https://` explicitly and is not localhost, keep it as-is.
- Preserve environment variables in URLs exactly as written (`$PROXY_IP`, `$ADMIN_URL`, etc.)
- `headers` is a YAML list — one entry per `-H` flag
- `body` should be valid JSON on a single line if possible. If it spans multiple lines, preserve it as a YAML block scalar.
- If there is no `-X` flag and there is a body, infer `method: POST`
- If there is no `-X` flag and no body, omit `method` (defaults to GET)
- Only include fields that are present in the original curl — do not add defaults

## Step 4: Build the {% http_request %} block

Output format:

```liquid
{% http_request %}
url: <url>
method: <METHOD>
headers:
  - "<Header: value>"
body:
  key: value
{% endhttp_request %}
```

Omit any field that has no value. `body` should be written as a YAML mapping if it's JSON, or as a quoted string if it's not valid JSON.

## Step 5: Report and confirm

Before editing any file, show the user:
1. Which files contain curl commands to convert
2. The before and after for each

Ask for confirmation before making any changes.

## Step 6: Apply changes

After confirmation, use the Edit tool to replace each curl code block with the `{% http_request %}` block. Do not change anything else in the file.

## Example

**Before:**

````markdown
```bash
curl -X POST http://localhost:8001/services \
  -H "Content-Type: application/json" \
  --json '{"name": "example", "url": "http://httpbin.org"}'
```
````

**After:**

```liquid
{% http_request %}
url: localhost:8001/services
method: POST
headers:
  - "Content-Type: application/json"
body:
  name: example
  url: http://httpbin.org
{% endhttp_request %}
```
