---
title: "decK state file format vs {{site.base_gateway}} DB-less format"
description: Learn how the decK state file format and Kong's DB-less declarative format differ, including when to use each one, metadata fields, and entity representation differences.
content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - deck

breadcrumbs:
  - /deck/

related_resources:
  - text: DB-less mode
    url: /gateway/db-less-mode/
  - text: deck file format
    url: /deck/file/format/

tags:
  - declarative-config
---

decK uses its own state file format, which differs from the declarative configuration format built into {{site.base_gateway}} for [DB-less mode](/gateway/db-less-mode/).
Both formats use YAML and share some metadata fields, but they represent certain entities differently and aren't directly compatible.

## When to use each format

The following table summarizes when to use each format:

<!--vale off-->
{% table %}
columns:
  - title: Format
    key: format
  - title: Use case
    key: usecase
rows:
  - format: DB-less
    usecase: |
      Backup and restore, or configuring {{site.base_gateway}} in DB-less mode. Export with `kong config db_export` and import with `kong config db_import`. 
  - format: decK
    usecase: Human-authored, version-controlled {{site.base_gateway}} configuration for a database-backed deployment. Designed for manual editing and GitOps workflows.
{% endtable %}
<!--vale on-->

If you're using {{site.base_gateway}} in [DB-less mode](/gateway/db-less-mode/), you can't use decK for `sync`, `dump`, or similar operations because they require write access to the Admin API.

If you're running {{site.base_gateway}} with a database in [traditional](/gateway/traditional-mode/) or in [hybrid mode](/gateway/hybrid-mode/), decK is the better choice for managing entity configuration.
The `kong config db_import` and `db_export` commands have several limitations:

* **Cache invalidation**: `db_import` initializes a {{site.base_gateway}} database but isn't safe to run while existing nodes are running.
Changes aren't propagated to live nodes, so you'd have to restart all nodes manually.
decK applies changes through the Admin API, so all nodes receive updates automatically.
* **Deletions**: `db_import` can add and update entities, but it can't delete them.
It won't remove entities that exist in the database but are absent from the config file.
* **Direct database access**: `db_import` needs a direct connection to the {{site.base_gateway}} database, which may not be available in production networking environments.
* **Drift detection**: decK can compare the configuration in {{site.base_gateway}}'s database against your config file and report differences.
This is useful for CI pipelines or scheduled drift checks.
* **Readability**: `deck gateway dump` produces a more human-readable file than `db_export`.

decK also has limitations to consider:

* **Performance at scale**: For very large installations, decK sync can be slow.
Mitigate this with distributed configuration and the `--parallelism` flag.
`db_import` is typically faster by orders of magnitude.
* **Hashed fields**: decK can't correctly export and re-import fields that are hashed in the database.
For example, the password of a `basic-auth` credential will be rehashed during sync, corrupting the value.

## Metadata fields

Both formats use metadata fields prefixed with an underscore (`_`).
Support for each field varies by format and target environment:

<!--vale off-->
{% feature_table %}
item_title: Field
columns:
  - title: decK (on-prem)
    key: deck_onprem
  - title: decK (Konnect)
    key: deck_konnect
  - title: DB-less
    key: dbless
  - title: Description
    key: description
features:
  - title: "`_format_version`"
    deck_onprem: true
    deck_konnect: true
    dbless: true
    description: The format version of the file.
  - title: "`_transform`"
    deck_onprem: true
    deck_konnect: true
    dbless: true
    description: Whether field transforms should be applied when loading the file.
  - title: "`_comment`"
    deck_onprem: false
    deck_konnect: false
    dbless: true
    description: A string field for storing opaque data. Kong ignores this field. Can appear on any entity, including the root object.
  - title: "`_ignore`"
    deck_onprem: false
    deck_konnect: false
    dbless: true
    description: An array field for storing opaque data. Kong ignores this field. Can appear on any entity, including the root object.
  - title: "`_workspace`"
    deck_onprem: true
    deck_konnect: false
    dbless: false
    description: Specifies the target workspace in a decK file.
  - title: "`_info`"
    deck_onprem: true
    deck_konnect: true
    dbless: false
    description: An object containing file-level metadata.
  - title: "`_info.select_tags`"
    deck_onprem: true
    deck_konnect: true
    dbless: false
    description: An array of tags used to filter which entities decK syncs or diffs.
  - title: "`_info.defaults`"
    deck_onprem: true
    deck_konnect: true
    dbless: false
    description: Default values applied to entities during sync.
  - title: "`_konnect`"
    deck_onprem: false
    deck_konnect: true
    dbless: false
    description: An object containing Konnect-specific file-level metadata.
  - title: "`_konnect.control_plane_name`"
    deck_onprem: false
    deck_konnect: true
    dbless: false
    description: The name of the control plane to target.
{% endfeature_table %}
<!--vale on-->

{:.warning}
> **Note:** Neither format includes a field to identify itself as a decK or DB-less file.
> You can't reliably detect the file type from its contents alone.

## Entity representation differences

The formats represent some entities differently, making them explicitly incompatible in certain areas.
Use [`deck file format`](/deck/file/format/) to convert between the two.

For example, to convert a DB-less file to decK format:
```sh 
deck file format deck dbless.yaml
```

Or, convert a decK file to DB-less format:
```sh
deck file format dbless deck.yaml
```

### Consumer Group plugins

In decK format, Consumer Group plugins are nested under each Consumer Group entry.
In DB-less format, they are stored in a top-level `consumer_group_plugins` array where each entry references its Consumer Group by name.

decK requires the Consumer Group to be defined in the same file, because the plugin is nested inside the group entry.
In DB-less format, `consumer_group_plugins` entries can exist independently.

<!--vale off-->
{% table %}
columns:
  - title: decK
    key: deck
  - title: DB-less
    key: dbless
rows:
  - deck: "`consumer_groups[*].plugins`"
    dbless: "`consumer_group_plugins`"
{% endtable %}
<!--vale on-->

To convert Consumer Groups from DB-less format to decK:
1. Rename `consumer_groups[*].consumer_group_plugins` to `consumer_groups[*].plugins` (merge if the key already exists).
1. Iterate over `consumer_group_plugins`.
1. For each entry, find the matching Consumer Group entry.
1. Append the plugin entry to the `plugins` array in that Consumer Group (create the array if it doesn't exist).

### Consumer Group membership

In decK format, Consumer Group membership is nested under each Consumer entry as an array of objects with a single `name` key.
In DB-less format, memberships are stored in a top-level `consumer_group_consumers` array where each entry references both a Consumer and a Consumer Group.

decK requires the Consumer to be defined in the same file, because membership is nested inside the Consumer entry.

<!--vale off-->
{% table %}
columns:
  - title: decK
    key: deck
  - title: DB-less
    key: dbless
rows:
  - deck: "`consumers[*].groups`"
    dbless: "`consumer_group_consumers`"
{% endtable %}
<!--vale on-->

To convert Consumers and their Consumer Groups from DB-less to decK:
1. Iterate over `consumer_group_consumers`.
1. For each entry, find the matching Consumer entry.
1. Create a `groups` array in the Consumer object if it doesn't exist.
1. Insert a new object with a single key `name` and the value set to `consumer_group_consumer.consumer_group`.
1. Add appropriate tags as needed.

### Plugin partials

In decK format, plugin Partial links are nested under each plugin entry as an array of objects with `name`, `id`, and optional `path` keys.
In DB-less format, they are stored in a top-level `plugins_partials` array where each entry references both a plugin and a Partial.

<!--vale off-->
{% table %}
columns:
  - title: decK
    key: deck
  - title: DB-less
    key: dbless
rows:
  - deck: "`plugins[*].partials`"
    dbless: "`plugins_partials`"
{% endtable %}
<!--vale on-->

To convert Partials from DB-less to decK:
1. Iterate over `plugins_partials`.
1. For each entry, find the matching plugin entry.
1. Create a `partials` array in the plugin object if it doesn't exist.
1. Insert a new object with `name` or `id` set to the Partial reference, and include `path` if specified.
If no `path` is provided, {{site.base_gateway}} uses the default path from the Partial's schema.

## Sample config comparison

The following examples show the same {{site.base_gateway}} entity configuration expressed in each format.

{% navtabs 'format-comparison' %}
{% navtab "DB-less" %}
{{site.base_gateway}} entity config, as exported by `kong config db_export`:

```yaml
_transform: false
_format_version: '3.0'

consumer_groups:
- name: A-team

consumer_group_plugins:
- name: rate-limiting-advanced
  consumer_group: A-team
  config:
    limit:
    - 1000
    retry_after_jitter_max: 0
    window_size:
    - 3600
    window_type: sliding

consumers:
- username: example-user1
  custom_id: user1
- username: example-user2
  custom_id: user2

consumer_group_consumers:
- consumer: example-user1
  consumer_group: A-team
- consumer: example-user2
  consumer_group: A-team

partials:
- id: c4ff03ed-478a-4b86-bdcf-811c45c00737
  name: my-redis-instance
  type: redis-ee
  config:
    port: 6379
    host: 127.0.0.1

plugins:
- id: 017320fe-ba14-4e14-8bac-3a7d1d3cd1e0
  name: rate-limiting-advanced
  config:
    strategy: redis
    sync_rate: -1
    limit:
    - 1000
    retry_after_jitter_max: 0
    window_size:
    - 3600
    window_type: sliding

plugins_partials:
- plugin: 017320fe-ba14-4e14-8bac-3a7d1d3cd1e0
  partial: c4ff03ed-478a-4b86-bdcf-811c45c00737
  path: config.redis
```
{% endnavtab %}
{% navtab "decK" %}

{{site.base_gateway}} entity config, as exported by `deck gateway dump`:

```yaml
_format_version: "3.0"

consumer_groups:
- name: A-team
  plugins:
  - config:
      limit:
      - 1000
      retry_after_jitter_max: 0
      window_size:
      - 3600
      window_type: sliding
    name: rate-limiting-advanced

consumers:
- custom_id: user1
  groups:
  - name: A-team
  username: example-user1
- custom_id: user2
  groups:
  - name: A-team
  username: example-user2

partials:
- config:
    host: 127.0.0.1
    port: 6379
  id: c4ff03ed-478a-4b86-bdcf-811c45c00737
  name: my-redis-instance
  type: redis-ee

plugins:
- id: 017320fe-ba14-4e14-8bac-3a7d1d3cd1e0
  name: rate-limiting-advanced
  config:
    strategy: redis
    sync_rate: -1
    limit:
    - 1000
    retry_after_jitter_max: 0
    window_size:
    - 3600
    window_type: sliding
  partials:
  - id: c4ff03ed-478a-4b86-bdcf-811c45c00737
    name: my-redis-instance
    path: config.redis
```
{% endnavtab %}
{% endnavtabs %}