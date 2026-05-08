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
- `removed:` lines are dropped commands (e.g. `app/_includes/kongctl/help/get/gateway/consumer.md` → `app/kongctl/get/gateway/consumer.md`). Process these with Step 2 before continuing.

### Step 2: Handle removed commands

For each removed command, do all four of the following.

#### Remove from parent index page

Find the parent index (e.g. `app/kongctl/get/gateway/consumer.md` → `app/kongctl/get/gateway/index.md`) and remove its table row. Do not reformat or reorder the table.

If the reference page doesn't exist locally, skip this sub-step.

#### Check the navigation index

Open `app/_indices/kongctl.yaml` and delete any entry that directly references the removed command's URL path. Sub-command pages are normally covered by glob patterns, but verify.

#### Remove crosslinks

Search for stale links and remove any `related_resources` entries or inline links pointing to the deleted URL:

```sh
grep -r "/kongctl/<verb>/<path/to/removed-command>/" app/
```

#### Add a redirect

Add a redirect in the `# kongctl` section of `app/_redirects`, pointing to the nearest parent that still exists:

```
/kongctl/<verb>/<path/to/removed-command>/   /kongctl/<verb>/
```

If the removed command had sub-pages, add a wildcard redirect too:

```
/kongctl/<verb>/<path/to/removed-command>/*  /kongctl/<verb>/
```

### Step 3: Create reference pages

For each new include file, create a matching `.md` page under `app/kongctl/`. For example, `get/event-gateway/backend-clusters.md` becomes `app/kongctl/get/event-gateway/backend-clusters.md`. Create any missing directories as needed.

Before creating pages, look at a few existing pages in the same directory to understand the established pattern — particularly the `works_on` values and `breadcrumbs` used there.

```yaml
---
title: <command name derived from directory path, e.g. "kongctl get event-gateway backend-clusters">
description: "<Short description of what the command does>"
content_type: reference
layout: reference

beta: true # kongctl is in beta, so all new pages need this flag; remove this flag when it reaches stable release.
works_on:
  # kongctl is a Konnect-native CLI. Set both on-prem and konnect only for pages
  # under /gateway/, since those commands interact with on-prem Gateway resources.
  # All other pages should be konnect only.
  - konnect

tools:
  - kongctl

breadcrumbs:
  # List each ancestor directory as a breadcrumb, derived from the page's path.
  # For example, app/kongctl/get/event-gateway/backend-clusters.md:
  - /kongctl/
  - /kongctl/get/
  - /kongctl/get/event-gateway/

related_resources:
  # Link to the nearest parent index page (the top-level verb index).
  - text: kongctl <verb> commands
    url: /kongctl/<verb>/
---

<Short description of what the command does, matching the description field above>

## Command usage

{% include_cached /kongctl/help/<path/to/include/file.md> %}
```

Run `kongctl <command> --help` and use the opening paragraph (the text before "Usage:") as the description. Apply these rules:

- Replace "Konnect" with `{{site.konnect_short_name}}`, "Event Gateway" with `{{site.event_gateway_short}}`, "Kong Gateway" with `{{site.base_gateway}}`
- In body text only (not `description` frontmatter): wrap verb names and subcommand names in backticks
- Use the first sentence for `description`; use the full paragraph for body text

### Step 4: Create index pages for new directories

For any new directory, create an `index.md` inside it (e.g. `app/kongctl/get/event-gateway/index.md`).

```yaml
---
title: <command group name, e.g. "kongctl get event-gateway">
description: "<Short description of what this group of commands does>"
content_type: reference
layout: reference

beta: true
works_on:
  - konnect  # same rules as Step 3

tools:
  - kongctl

breadcrumbs:
  # Same as the subcommand pages in this directory, derived from the directory path.
  - /kongctl/
  - /kongctl/<verb>/
  - /kongctl/<verb>/<command>/

related_resources:
  - text: kongctl <verb> commands
    url: /kongctl/<verb>/
---

<Short description of what this group of commands does>

kongctl provides the following tools for <what this group does, e.g. "retrieving resources and resource details for {{site.event_gateway_short}}">:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl <verb> <command> <subcommand>](/kongctl/<verb>/<command>/<subcommand>/)
    description: "Short formatted description of the subcommand."
  # ... one row per subcommand in this directory
{% endtable %}

## Command usage

{% include_cached /kongctl/help/<path/to/index/include.md> %}
```

Run `kongctl <command group> --help` to get the opening description and subcommand list. Apply the same rules as Step 3.

### Step 5: Update parent index pages

For each new page (and each new index page), add a row to the parent index. Insert rows in alphabetical order by command name.

For example:
- `app/kongctl/get/dcr-provider.md` → add a row to `app/kongctl/get/index.md`
- `app/kongctl/get/event-gateway/` directory → add a row to `app/kongctl/get/index.md`
- `app/kongctl/get/event-gateway/backend-clusters.md` → add a row to `app/kongctl/get/event-gateway/index.md`

### Step 6: Update the navigation index

Update `app/_indices/kongctl.yaml` only when a **new top-level command** is added (e.g. `explain`, `scaffold`). Subcommand pages under an existing verb are covered by existing glob patterns and don't need changes.

For a new top-level command, add a section under "CLI References" in alphabetical order:

```yaml
      - title: <Descriptive section title>
        items:
            - path: /kongctl/<verb>/
            - path: /kongctl/<verb>/*/**    # add if verb has subcommand groups
            - path: /kongctl/<verb>/*/**/** # add if verb has 3+ level nesting
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
