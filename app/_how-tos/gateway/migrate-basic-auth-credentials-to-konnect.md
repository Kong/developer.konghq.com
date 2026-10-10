---
title: Migrate Basic Authentication credentials to Konnect
permalink: /how-to/migrate-basic-auth-credentials-to-konnect/
content_type: how_to

description: Migrate existing Basic Authentication Consumer credentials from a self-managed deployment to Konnect without resetting passwords, using decK's `--skip-hash-for-basic-auth` flag.

products:
  - gateway

plugins:
  - basic-auth

works_on:
  - konnect

tools:
  - deck

entities:
  - consumer
  - plugin

tags:
  - migration
  - authentication
  - credentials

automated_tests: false

tldr:
  q: How do I migrate existing Basic Authentication credentials to Konnect without resetting passwords?
  a: |
    Export your self-managed configuration with `deck gateway dump --with-id` so Consumer IDs are preserved, since each password hash is salted with its Consumer's ID. Import the state file into Konnect with `deck gateway sync --skip-hash-for-basic-auth` (or set `_info.skip_hash_for_basic_auth: true` in the file). Konnect stores the hash as-is instead of hashing it again, so existing credentials keep authenticating with their original passwords.

prereqs:
  skip_product: true
  inline:
    - title: A self-managed deployment with existing Basic Authentication credentials
      content: |
        You have a self-managed {{site.base_gateway}} deployment with Consumers that authenticate using the [Basic Authentication plugin](/plugins/basic-auth/). See [Authenticate Consumers with basic authentication](/how-to/authenticate-consumers-with-basic-authentication/) if you're setting this up for the first time.
      icon_url: /assets/icons/lock.svg
    - title: decK 1.52.0 or later
      content: |
        The `--skip-hash-for-basic-auth` flag was added in decK 1.52.0. Check your version:

        ```bash
        deck version
        ```
      icon_url: /assets/icons/code.svg
    - title: Back up your target Konnect control plane
      content: |
        Migrating credentials writes directly into the Consumer store of the target control plane. Before you begin, back up its current state:

        ```bash
        deck gateway dump --konnect-control-plane-name <control-plane> --with-id -o backup.yaml
        ```

        {:.warning}
        > If the target control plane already holds configuration you don't own, scope every command in this guide to your own entities with `--select-tag` (or `_info.select_tags` in the state file). Otherwise `deck gateway sync` can delete configuration outside your migration.
      icon_url: /assets/icons/service-document.svg

related_resources:
  - text: "Migrating from self-managed {{site.base_gateway}} to {{site.konnect_short_name}}"
    url: /gateway/self-managed-migration/
  - text: Basic Authentication plugin
    url: /plugins/basic-auth/
  - text: Authenticate Principals with basic authentication
    url: /how-to/authenticate-principals-with-basic-authentication/
  - text: decK
    url: /deck/

next_steps:
  - text: "Migrating from self-managed {{site.base_gateway}} to {{site.konnect_short_name}}"
    url: /gateway/self-managed-migration/
  - text: Authenticate Principals with basic authentication
    url: /how-to/authenticate-principals-with-basic-authentication/

search_aliases:
  - migrate basic auth to konnect
  - basic-auth hash migration
  - skip-hash-for-basic-auth
  - pre-hashed basic-auth credentials
---

The [Basic Authentication plugin](/plugins/basic-auth/) never stores a Consumer's password. It stores a hash of the password salted with the Consumer's ID, so a plain [decK](/deck/) dump and sync can't carry credentials between deployments: the source hash is written to the target as a literal password value and gets hashed a second time, breaking authentication for every migrated Consumer.

Konnect can accept the hash as-is instead of hashing it again, so you can migrate Consumers and their credentials without asking anyone to reset a password. This guide walks through that migration and the operational pitfall that catches most first attempts.

## Why credential migration needs special handling

A Basic Authentication credential's password field holds a hash, not the password itself:

* {{site.base_gateway}} 3.14 and later write `SHA-256(password + consumer_id)`.
* Earlier versions write `SHA-1(password + consumer_id)`.

The Consumer ID is part of the salt. If a Consumer is recreated in Konnect with a new ID, its existing hash can never verify again, no matter how carefully the rest of the migration goes. This is also why a Consumer's credentials can't be recreated from scratch with the same plaintext password and expected to match: the ID has to be the same one the hash was generated with.

decK is aware that a default dump and sync won't work here. Both `deck gateway dump` and `deck gateway sync` print a warning when they encounter Basic Authentication credentials:

```text
Warning: import/export of basic-auth credentials using decK doesn't work due to hashing of passwords in Kong.
```

The `--skip-hash-for-basic-auth` flag on `deck gateway sync` and `deck gateway apply` (Konnect only) tells Konnect to store the hash you send exactly as you send it, instead of re-hashing it. Combined with preserving Consumer IDs, that's enough to move a credential intact.

## Export your configuration with Consumer IDs preserved

Dump your self-managed workspace with `--with-id`. This is required, not optional: without it, decK generates new IDs for every entity, which breaks the hash salt for every Consumer in the file.

```bash
deck gateway dump \
  --workspace <workspace> \
  --with-id \
  -o migration.yaml
```

decK confirms it exported IDs:

```text
Warning: basic-auth credentials detected, IDs will be exported
```

Check that every Consumer has an ID, and that every credential hash is 40 characters (SHA-1) or 64 characters (SHA-256) of lowercase hex:

```bash
yq eval '[.consumers[] | select(has("id") | not)] | length' migration.yaml   # must print 0

yq eval '.consumers[] | [.username, .basicauth_credentials[0].password] | @tsv' migration.yaml \
  | awk -F'\t' '{ printf "%-24s %d chars\n", $1, length($2) }'
```

{:.warning}
> From this point, `migration.yaml` contains password-equivalent material. Treat it like a secret: keep it out of version control, and delete it once the migration is verified.

## Prepare the state file for Konnect

A dump taken with `--with-id` needs very little changed. Remove the Workspace reference (Konnect has no Workspaces), point the file at your target control plane, and set `skip_hash_for_basic_auth`:

```bash
yq eval '
    del(._workspace)
  | ._konnect.control_plane_name = "<control-plane>"
  | ._info.skip_hash_for_basic_auth = true
' migration.yaml > migration-konnect.yaml
```

If the target control plane already has configuration you don't own, add `_info.select_tags` scoped to tags on the entities in this file, so `deck gateway sync` can only ever see and modify your migration's own entities.

## Preview the import

`deck gateway diff` doesn't accept `--skip-hash-for-basic-auth` as a flag. Setting `_info.skip_hash_for_basic_auth: true` in the file, as done in the previous step, is what makes the dry run and the sync agree on the same behavior.

```bash
deck gateway diff migration-konnect.yaml \
  --konnect-control-plane-name <control-plane>
```

Confirm the plan only creates the Consumers and credentials you expect, and that it reports no deletions. If deletions appear, your tag or file scope is wider than intended. Stop and narrow it before continuing.

## Import the credentials

```bash
deck gateway sync migration-konnect.yaml \
  --konnect-control-plane-name <control-plane> \
  --skip-hash-for-basic-auth
```

For a phased migration, use `deck gateway apply` in place of `sync`. `apply` only ever creates or updates entities in the file. It never deletes anything, so you can migrate Consumers in waves, one file per wave, while the rest continue to authenticate against your self-managed deployment.

## Validate

Confirm the hash arrived unchanged, then confirm a real request authenticates with the original password.

```bash
deck gateway dump --konnect-control-plane-name <control-plane> --with-id -o verify.yaml

diff <(yq eval '.consumers[] | [.username, .basicauth_credentials[0].password] | @tsv' migration-konnect.yaml | sort) \
     <(yq eval '.consumers[] | [.username, .basicauth_credentials[0].password] | @tsv' verify.yaml | sort)

curl -i -u '<username>:<original-password>' https://<konnect-data-plane>/<route>
```

A matching `diff` confirms the hash was stored as sent. The `curl` request is the check that actually matters: it proves the original password still authenticates through a live Konnect data plane.

## Fix a credential that was imported without the flag

If a credential was imported before this guide, or without `--skip-hash-for-basic-auth`, Konnect will have hashed an already-hashed value. Re-running `deck gateway sync` with the flag afterwards does **not** fix it.

{:.warning}
> decK compares existing Basic Authentication credentials without looking at the password field. If a credential with the same ID already exists in the target control plane, a password-only difference produces no update, so re-syncing with the correct flag reports zero changes and the credential is still broken.

To repair it, delete the credential in Konnect first, then re-run the import:

```bash
deck gateway apply migration-konnect.yaml \
  --konnect-control-plane-name <control-plane> \
  --skip-hash-for-basic-auth
```

This time decK creates the credential fresh, since nothing with that ID exists yet, and the stored hash matches what was sent.

## Alternative approaches

If you'd rather not migrate hashes at all, two other options exist:

* [Authenticate Principals with basic authentication](/how-to/authenticate-principals-with-basic-authentication/) using Kong Identity. This decouples authentication from the Consumer store, but it means provisioning new Principal credentials. It doesn't reuse your existing hashes.
* A custom plugin that validates the `Authorization` header against your own credential store in its `access` phase. This works with Konnect because it makes no control plane database writes, but it means owning and maintaining the plugin.

For migrating an existing Consumer estate as-is, importing pre-hashed credentials is simpler than either.
