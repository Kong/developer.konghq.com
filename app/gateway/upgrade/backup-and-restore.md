---
title: "Back up and restore {{site.base_gateway}}"
description: Learn how to back up and restore your {{site.base_gateway}} data.
content_type: reference
layout: reference
breadcrumbs:
    - /gateway/
    - /gateway/upgrade/
products:
    - gateway

works_on:
    - on-prem

tags:
    - upgrades
    - backup
    - restore

related_resources:
  - text: "Upgrading {{site.base_gateway}}"
    url: /gateway/upgrade/
  - text: Rolling upgrade
    url: /gateway/upgrade/rolling/
  - text: "Dual-cluster upgrade"
    url: /gateway/upgrade/dual-cluster/
  - text: In-place upgrade
    url: /gateway/upgrade/in-place/
  - text: "{{site.base_gateway}} breaking changes"
    url: /gateway/breaking-changes/
---

Before you start any upgrade, back up your {{site.base_gateway}} data.

Kong supports two back up methods for {{site.base_gateway}} entities: [database-native backup](#database-native-backup) and [declarative backup](#declarative-backup).
A database-native backup backs up the entire {{site.base_gateway}} database, while a declarative backup works by managing declarative configuration files.

We recommend backing up data using both methods when possible, as this offers recovery flexibility:
* The database-native tools are robust and can restore data instantly, compared to the declarative tools.
* In case of data corruption, try to do a database-level restore first, otherwise bootstrap a new database and use [declarative tools](#declarative-tools-for-backup-and-restore) to load in entity data.

When running {{site.base_gateway}} in {{site.konnect_short_name}}, only [declarative backup is available](#back-up-a-konnect-control-plane), as Kong manages the database.

[Keyring materials](#keyring-materials-backup-and-restore) and {{site.base_gateway}} [configuration files](#other-files) must be backed up separately.
See their respective sections below for details.

The backup and restore methods described in this guide serve as general instructions.
Revise the methods as necessary to fit your infrastructure, deployment, and business requirements.

## Declarative tools for backup and restore

Kong ships two declarative backup tools: [decK](/deck/) and the [kong config CLI](/gateway/cli/reference/), which support managing {{site.base_gateway}} entities in the declarative format.

* For **database-backed deployments** (traditional and hybrid mode), backups taken with either of these tools serve as an extra safeguard layer. If the database-native backup or restore corrupts the database, you can fall back to declarative files for restoring data.

    Both tools require the database to be ready for data export and import. To import or export data using these tools, ensure the user and password are initialized, and the database is bootstrapped.

* For **DB-less deployments**, no special tools are needed, so there is no declarative tool support. Back up your declarative files manually.

decK is generally more powerful than the kong config CLI. It has more features, invalidates the cache automatically, and fetches entities from the database instead of the LRU cache. Additionally, it overwrites entities instead of patching, so that the database has the exact copy of the config that you provide.

However, decK also has its limitations:

* **Availability**: decK requires {{site.base_gateway}} to be online, while the kong config CLI doesn't.

* **Performance**: decK uses the Admin API to read and write entities and might take longer than expected, especially when the number of entities is very large.

  You can resolve this by increasing the number of threads by passing the flag `--parallelism` to [`deck gateway sync`](/deck/gateway/sync/)
  or [`deck gateway diff`](/deck/gateway/diff/), or use decK’s
  [federated configuration](/deck/apiops/federated-configuration/) feature.

* **Entities managed by decK**: decK does not manage Enterprise-only entities, like [RBAC roles](/gateway/entities/rbac/#default-kong-gateway-roles), credentials, [Keyring](/gateway/keyring/), [license](/gateway/entities/license/), and so on. Configure these security related entities separately using the Admin API or Kong Manager.
See the reference for [Entities managed by decK](/deck/reference/entities/) for a full list.

Due to these limitations, we recommend prioritizing the [database-native method](#database-native-backup) in deployments using a database.

## Back up and restore Gateway entities for a {{site.konnect_short_name}} Control Plane

If you're running {{site.base_gateway}} as a Control Plane in {{site.konnect_short_name}}, use decK for backup and restore.
Review the list of [entities managed by decK](/deck/reference/entities/) to see what can be backed up using this method.

{:.info}
> **Note:** This method only backs up Control Plane configurations in Gateway Manager. 
It does not back up Dev Portal, API Products, Service Catalog, and so on. 
Data stored in these applications, such as API specs and documents, must be manually backed up.

### Back up a {{site.konnect_short_name}} Control Plane

Use `deck gateway dump` to back up your configuration:

```sh
deck gateway dump -o my-backup.yaml \
  --konnect-token $KONNECT_TOKEN \
  --konnect-control-plane-name $CONTROL_PLANE_NAME
```

This command generates a state file for the Control Plane's entity
configuration, for example:

```yaml
_format_version: "3.0"
_konnect:
    control_plane_name: us-west
consumers:
- username: example-user1
- username: example-user2
services:
- connect_timeout: 60000
    host: httpbin.konghq.com
    name: MyService
    tags:
    - _KonnectService:example_service
    ...
```

### Restore a {{site.konnect_short_name}} Control Plane

You can restore entity configuration for a Control Plane using a declarative configuration file.
You must do this for one group at a time.

Assuming you have a backup file, for example, `my-backup.yaml`:

1. Run a diff between your backup file and the Control Plane in {{site.konnect_short_name}} to 
make sure you're applying the configuration you want:

   ```sh
   deck gateway diff my-backup.yaml \
     --konnect-token $KONNECT_TOKEN \
     --konnect-control-plane-name $CONTROL_PLANE_NAME
   ```

2. If you're satisfied with the diff result, run `deck gateway sync` to sync your configuration to 
a Control Plane:

   ```sh
   deck gateway sync my-backup.yaml \
     --konnect-token $KONNECT_TOKEN \
     --konnect-control-plane-name $CONTROL_PLANE_NAME
   ```

Check your Control Plane in {{site.konnect_short_name}} to make sure the sync worked. 
Open [Gateway Manager](https://cloud.konghq.com/gateway-manager/), select your Control Plane, and check through the configured entities.

## Back up and restore Gateway entities in a self-managed deployment

The following sections explain the different backup methods.

### Back up a self-managed deployment

Use a combination of database-native and declarative backups to safely preserve your data.

#### Database-native backup

When upgrading your {{site.base_gateway}} to a newer version, you have to perform a database migration using the [`kong migrations`](/gateway/cli/reference/#kong-migrations) utility. The `kong migrations` commands are not reversible. We recommend backing up data before any starting any upgrade in case of any migration issues.

If you are running {{site.base_gateway}} with a database, run a database dump of raw data so that you can recover the database quickly in a database-native way. This is the recommended way to back up {{site.base_gateway}}.

With PostgreSQL, you can dump data in _text_ format, _tar_ format (no compression), or _directory_ format (with compression) using the utility `pg_dump`. For example:

```sh
pg_dump -U kong -d kong -F d -f kongdb_backup_20230816
```

Use the CLI option `-d` to specify the database (for example, `kong`) to export, especially when the PostgreSQL instance also serves applications other than {{site.base_gateway}}.

#### Declarative backup

{% navtabs "declarative-mode" %}
{% navtab "Traditional or hybrid mode - decK" %}

For a database-backed deployment, we recommend using decK as a secondary backup method.

{:.warning}
> Never use this method as your primary backup, as it doesn't back up all {{site.base_gateway}} entities.

1. To back up data with decK, first make sure it successfully connects to {{site.base_gateway}}:

    ```sh
    deck gateway ping
    ```

    If you have [RBAC enabled](/how-to/enable-rbac-with-admin-api/), use the CLI option `--headers` to
    specify the admin token. You can specify this token with any decK command:

    ```sh
    deck gateway ping --headers “Kong-Admin-Token: $PASSWORD”
    ```

2. Use decK to dump the configuration.
You can back up a particular Workspace or all Workspaces at once:

    ```sh
    deck gateway dump --all-workspaces -o ./kong_backup.yaml
    ```
    or
    ```sh
    deck gateway dump --workspace it_dept -o ./kong_backup.yaml
    ```

3. Store the resulting file or files in a secure location.


{% endnavtab %}
{% navtab "Traditional or hybrid mode - kong config CLI" %}

As a final fail-safe for a database-backed deployment, you can also back up the database using the [`kong config`](/gateway/cli/reference/#kong-config) CLI.

{:.warning}
> Never use this method as your primary backup, as it might not accurately represent the final state of your database.

```sh
kong config db_export ./kong_backup.yaml
```

{% endnavtab %}
{% navtab "DB-less mode" %}

To back up a DB-less deployment, make a copy of your declarative configuration file (`kong.yml` by default) and store it in a safe place.

You can find your declarative config file at the path set via the [`declarative_config`](/gateway/configuration/#declarative-config) setting.

{% endnavtab %}
{% endnavtabs %}

### Restore a self-managed deployment 

Restore {{site.base_gateway}} entity configuration from database-native and declarative backups.

#### Database-native restore

To recover {{site.base_gateway}} configuration data from a database-native backup, make sure the database is prepared first.

For PostgreSQL:

1. In `kong.conf`, set a database user using the `pg_user` parameter:

    ```
    pg_user = kong
    ```

2. In `kong.conf`, set a database name using the `pg_database` parameter:

    ```
    pg_database = kong
    ```

3. Bootstrap database entities using the `migrations` command.
Refer to the [`kong migrations` CLI reference](/gateway/cli/reference/#kong-migrations)
for more information.

    ```sh
    kong migrations bootstrap
    ```

4. You can now restore the data using the utility `pg_restore`:

    ```sh
    pg_restore -U kong -C -d postgres --if-exists --clean kongdb_backup_20230816/
    ```

#### Declarative restore

If you need to roll back, change the {{site.base_gateway}} instance back to the original version,
validate the declarative config, then apply it to your {{site.base_gateway}} instance.

{% navtabs "declarative-mode" %}
{% navtab "Traditional or hybrid mode - decK" %}

In traditional or hybrid mode, use decK to restore your configuration from a backup state file.

1. Check that {{site.base_gateway}} is online:

    ```sh
    deck gateway ping
    ```
2. Validate the declarative config:

    ```sh
    deck gateway validate ./kong_backup.yaml [--online] 
    ```

3. Once verified, restore a particular workspace or all workspaces at once:

    ```sh
    deck gateway sync ./kong_backup.yaml --all-workspaces 
    ```
    or

    ```sh
    deck gateway sync ./kong_backup.yaml --workspace it_dept
    ```

{% endnavtab %}
{% navtab "Traditional or hybrid mode - kong config CLI" %}

If you backed up {{site.base_gateway}} database using [`kong config db_export`](/gateway/cli/reference/#kong-config),
use the kong config CLI to restore your configuration from the backup declarative config file.

1. Validate the backup configuration file before restoring it:

    ```sh
    kong config parse ./kong_backup.yaml
    ```

2. Import entities into your database:

    ```sh
    kong config db_import ./kong_backup.yaml
    ```

2. Restart or reload your {{site.base_gateway}} instance:

    ```sh
    kong restart
    ```

    or

    ```sh
    kong reload
    ```

{% endnavtab %}
{% navtab "DB-less mode" %}

In DB-less mode, use the kong config CLI to restore your configuration from a declarative config file.

1. Validate the backup configuration file before restoring it:

    ```sh
    kong config parse ./kong_backup.yaml
    ```

2. Restart or reload your {{site.base_gateway}} instance using the backup configuration file:

    ```sh
    export KONG_DECLARATIVE_CONFIG=./kong_backup.yaml; kong restart -c ./kong.conf
    ```

    or

    ```
    export KONG_DECLARATIVE_CONFIG=./kong_backup.yaml; kong reload -c ./kong.conf
    ```

    Alternatively, post the declarative backup file to the `:8001/config` endpoint:

    ```sh
    curl -sS http://localhost:8001/config?check_hash=1 \
      -F 'config=@./kong_backup.yaml' ; echo
    ```

{% endnavtab %}
{% endnavtabs %}

## Keyring materials backup and restore

If you have enabled [Keyring](/gateway/keyring/) and data encryption, you must separately back up and restore Keyring materials.

{:.warning}
> **Caution**: Make sure to store the encryption key in a safe place.
If the encryption key is lost, you will permanently lose access to the encrypted {{site.base_gateway}}
configuration data and there is no other way to recover it.

For technical details, refer to the [disaster recovery documentation](/gateway/keyring/#disaster-recovery).

## Other files to back up

Manually back up the following files:

* {{site.base_gateway}} configuration file `kong.conf`.
* Files in the {{site.base_gateway}} prefix, such as [Keys](/gateway/entities/key/), [Certificates](/gateway/entities/certificate/), `nginx-kong.conf`, and any others you may have.
* Any other files you have created for your {{site.base_gateway}} deployment.

Although these files don't contain {{site.base_gateway}} entities, without them, you won't be able to launch {{site.base_gateway}}.

{:.info}
> **Note**: If you have built a commercial offering where {{site.base_gateway}} is stateless -- that is, where everything
that gets configured on either the AMI or the Docker container is defined in version control and pushed into the
platform that it's running on -- back up {{site.base_gateway}}'s configuration parameters in your own operational or secure way.
