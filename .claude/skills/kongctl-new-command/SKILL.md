---
name: kongctl-new-command
description: "Syncs kongctl reference docs after a release: creates pages for new commands, removes pages for dropped commands, and updates navigation indexes and redirects. Trigger when the user runs '/kongctl-new-command', shares a 'Sync kongctl Releases' PR, or asks to update pages under app/kongctl/."
---

# kongctl command docs skill

Generates reference pages and index updates for new kongctl commands, using pre-generated include files from `app/_includes/kongctl/help` as the source of truth.

## Invocation

**Option A: Pass a GitHub PR link**

```
/kongctl-new-command https://github.com/Kong/developer.konghq.com/pull/<PR-NUMBER>
```

Start at Step 1.

**Option B: Pass a command path directly**

Pass a file or glob relative to `app/_includes/kongctl/help`:

```
/kongctl-new-command get/event-gateway/*
/kongctl-new-command get/event-gateway/backend-clusters.md
```

If any paths correspond to removed commands (the include file no longer exists), handle those with Step 2 first, then skip to Step 3 for new ones.

## Prerequisites

Check that `kongctl` is installed. If not, ask the user before installing:

```sh
which kongctl && kongctl version
# If missing: brew install kongctl (or: brew upgrade kongctl)
```

Only run kongctl commands with the `--help` flag.

## Step-by-step instructions

### Step 1: Identify new and removed commands from the PR

> Only needed for Option A. Skip to Step 2 if you used Option B.

Fetch added and removed include files from the PR (use `--paginate` — these PRs often touch 100+ files):

```sh
gh api repos/Kong/developer.konghq.com/pulls/<PR-NUMBER>/files \
  --paginate \
  --jq '.[] | select(.status == "added" or .status == "removed") | "\(.status): \(.filename)"' \
  | grep "app/_includes/kongctl/help"
```

The output will look like:

```
added: app/_includes/kongctl/help/get/extension.md
removed: app/_includes/kongctl/help/get/gateway/consumer.md
```

- `added:` lines are new include files. Strip the `app/_includes/kongctl/help/` prefix to get the `<COMMAND-PATH>` for each.
- `removed:` lines are dropped commands. Strip the `app/_includes/kongctl/help/` prefix to get the command path (e.g. `get/gateway/consumer`), then process with Step 2 before continuing.

### Step 2: Handle removed commands

For each removed command, do all four of the following.

#### Remove from parent file

Determine where the command lives:

- **3-level command** (e.g. `get/event-gateway/backend-clusters`): it's a `###` section in the flat file `app/kongctl/get/event-gateway.md`. Remove the entire `###` section (heading, description paragraph, and `{% include_cached %}` line). Do not reformat the rest of the file.
- **2-level command** (e.g. `get/dcr-provider`): it's its own `.md` file (`app/kongctl/get/dcr-provider.md`). Remove its table row from `app/kongctl/get/index.md` and delete the file.

If the file or section doesn't exist locally, skip this sub-step.

#### Check the navigation index

Open `app/_indices/kongctl.yaml` and delete any entry that directly references the removed command's URL path. Sub-command pages are normally covered by glob patterns, but verify.

#### Remove crosslinks

Search for stale links and remove any `related_resources` entries or inline links pointing to the deleted URL:

```sh
grep -r "/kongctl/<verb>/<path/to/removed-command>/" app/
```

#### Add a redirect

Add a redirect in the `# kongctl` section of `app/_redirects`:

- **3-level command**: redirect to the anchor on the parent page:
  ```
  /kongctl/<verb>/<resource>/<subcommand>/   /kongctl/<verb>/<resource>/#kongctl-<verb>-<resource>-<subcommand>
  ```
- **2-level command**: redirect to the verb index:
  ```
  /kongctl/<verb>/<removed-command>/   /kongctl/<verb>/
  ```

For a removed 2-level command that previously had a resource group (e.g. `get/event-gateway` being dropped entirely), also add a wildcard redirect:
```
/kongctl/<verb>/<removed-command>/*  /kongctl/<verb>/
```

### Step 3: Create reference pages

The structure depends on command depth:

**2-level commands** (e.g. `get/dcr-provider`) become standalone `.md` files at `app/kongctl/get/dcr-provider.md`. Before creating, look at neighboring files in the same directory for the established pattern — particularly `works_on` and `breadcrumbs`.

```yaml
---
title: <command name, e.g. "kongctl get dcr-provider">
description: "<Short description of what the command does>"
content_type: reference
layout: reference

works_on:
  # kongctl is a Konnect-native CLI. Set both on-prem and konnect only for pages
  # under /gateway/, since those commands interact with on-prem Gateway resources.
  # All other pages should be konnect only.
  - konnect

tools:
  - kongctl

breadcrumbs:
  # List each ancestor as a breadcrumb. For app/kongctl/get/dcr-provider.md:
  - /kongctl/
  - /kongctl/get/

related_resources:
  - text: kongctl <verb> commands
    url: /kongctl/<verb>/
---

<Short description of what the command does>

## Command usage

{% include_cached /kongctl/help/<path/to/include/file.md> %}
```

**3-level commands** (e.g. `get/event-gateway/backend-clusters`) are NOT standalone files. They are added as `###` sections within the flat parent file `app/kongctl/get/event-gateway.md`. See Step 5 for how to add them.

Run `kongctl <command> --help` and use the opening paragraph (the text before "Usage:") as the description. Apply these rules:

- Replace "Konnect" with `{{site.konnect_short_name}}`, "Event Gateway" with `{{site.event_gateway_short}}`, "Kong Gateway" with `{{site.base_gateway}}`
- In body text only (not `description` frontmatter): wrap verb names and subcommand names in backticks
- Use the first sentence for `description`; use the full paragraph for body text

### Step 4: Create resource group pages for new command groups

When a new resource group appears (e.g. `get/event-gateway/` in the includes), create a flat `.md` file at `app/kongctl/get/event-gateway.md` — not an `index.md` in a directory.

```yaml
---
title: <command group name, e.g. "kongctl get event-gateway">
description: "<Short description of what this group of commands does>"
content_type: reference
layout: reference

works_on:
  - konnect  # same rules as Step 3

tools:
  - kongctl

breadcrumbs:
  # List ancestor paths only (not the page's own URL).
  # For app/kongctl/get/event-gateway.md:
  - /kongctl/
  - /kongctl/get/

related_resources:
  - text: kongctl <verb> commands
    url: /kongctl/<verb>/
---

<Short description of what this group of commands does>

## Command usage

{% include_cached /kongctl/help/<verb>/<resource>/index.md %}

### kongctl <verb> <resource> <subcommand>

<Short description of what this subcommand does>

{% include_cached /kongctl/help/<verb>/<resource>/<subcommand>.md %}
```

Run `kongctl <command group> --help` to get the opening description and subcommand list. Apply the same rules as Step 3.

### Step 5: Update parent index pages

Add rows in alphabetical order by command name.

- **New 2-level command** (e.g. `get/dcr-provider`): add a row to `app/kongctl/get/index.md` with a page link: `[kongctl get dcr-provider](/kongctl/get/dcr-provider/)`
- **New resource group** (e.g. `get/event-gateway`): add a row to `app/kongctl/get/index.md` with a page link: `[kongctl get event-gateway](/kongctl/get/event-gateway/)`
- **New 3-level subcommand** (e.g. `get/event-gateway/backend-clusters`): add a `###` section to `app/kongctl/get/event-gateway.md` in alphabetical order among the existing sections in that file.

### Step 6: Update the navigation index

Update `app/_indices/kongctl.yaml` only when a **new top-level command** is added (e.g. `explain`, `scaffold`). Subcommand pages under an existing verb are covered by existing glob patterns and don't need changes.

For a new top-level command, add a section under "CLI References" in alphabetical order:

```yaml
      - title: <Descriptive section title>
        items:
            - path: /kongctl/<verb>/
            - path: /kongctl/<verb>/*/**    # add if verb has subcommand groups
```

For example, `explain` (no subcommands) becomes:

```yaml
      - title: Explain Schema
        items:
            - path: /kongctl/explain/
```

### Step 7: Summarize and report to the user

List the following:
* New pages created
* Pages updated
* Removed commands processed (index entries removed, redirects added, crosslinks cleaned up)
* Commands that were checked and help text that was pulled from them
