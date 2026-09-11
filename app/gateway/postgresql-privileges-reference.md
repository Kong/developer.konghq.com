---
title: PostgreSQL privileges reference
content_type: reference
layout: reference

breadcrumbs:
  - /gateway/

products:
  - gateway

works_on:
  - on-prem

tier: enterprise

min_version:
  gateway: '3.16'

tags:
  - database

description: Reference for the minimal PostgreSQL privileges {{site.base_gateway}} needs for migrations, runtime operations, and admin CLI commands.

related_resources:
  - text: Configure the {{site.base_gateway}} datastore on Linux
    url: /how-to/configure-datastore/
  - text: PostgreSQL TLS configuration reference
    url: /gateway/postgresql-tls-reference/
  - text: "{{site.base_gateway}} PostgreSQL OAuth2 authentication"
    url: /gateway/postgresql-oauth/

faqs:
  - q: Does the {{site.base_gateway}} database user need superuser privileges?
    a: |
      No. The write user needs the `LOGIN` attribute only. It does not need `SUPERUSER`, `CREATEDB`, or `CREATEROLE`.

  - q: Can I use one PostgreSQL role for both migrations and runtime?
    a: |
      Yes. This is the simplest setup. When the same role runs `kong migrations` and the gateway process, that role owns the schema and every object in it. Ownership already grants the runtime session every privilege it needs. As a result, no `GRANT` statement is necessary.

  - q: Why does `kong workspace rename` need `TRUNCATE`, when the runtime session never uses it?
    a: |
      `kong workspace rename` and `kong config db_import` call `truncate_clustering_sync_version()` to reset the clustering sync state. This call runs in a separate, non-pooled admin CLI connection, not in a runtime session. Grant `TRUNCATE` only to the role that runs these commands.

  - q: Does a Hybrid mode data plane need any PostgreSQL privileges?
    a: |
      No. A data plane node (`role = data_plane`) always runs with `database = off`. It receives configuration over the cluster websocket from the control plane, and it never opens a database connection.

  - q: Does Traditional db-less mode need any PostgreSQL privileges?
    a: |
      No. In Traditional db-less mode (`database = off`), {{site.base_gateway}} loads configuration from a declarative file instead of a database. It never opens a database connection.
---

This reference lists the minimum PostgreSQL role attributes and privileges that {{site.base_gateway}} needs for migrations, runtime operations, and admin CLI commands. Use these privileges instead of full database ownership. This follows the principle of least privilege.

This reference covers {{site.base_gateway}} core and its bundled plugins only. A custom plugin can define its own DAOs, migrations, tables, and triggers. If you use a custom plugin, grant the write user the extra privileges its code needs.

## Configuration parameters

The following `kong.conf` parameters control which PostgreSQL role {{site.base_gateway}} connects as. See the [configuration reference](/gateway/configuration/#datastore-section) for the full list of datastore parameters.

<!--vale off-->
{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Default
    key: default
  - title: Description
    key: description
rows:
  - parameter: "[`pg_user`](/gateway/configuration/#pg-user)"
    default: "`kong`"
    description: PostgreSQL role name for the write user.
  - parameter: "[`pg_password`](/gateway/configuration/#pg-password)"
    default: (none)
    description: Password for the write user.
  - parameter: "[`pg_database`](/gateway/configuration/#pg-database)"
    default: "`kong`"
    description: Database name.
  - parameter: "[`pg_schema`](/gateway/configuration/#pg-schema)"
    default: `public`
    description: Schema name.
  - parameter: "[`pg_ro_host`](/gateway/configuration/#pg-ro-host)"
    default: (none)
    description: Host of the read-only Postgres server. Setting this activates Kong's read-only database connection feature."
  - parameter: "[`pg_ro_user`](/gateway/configuration/#pg-ro-user)"
    default: Falls back to `pg_user`
    description: PostgreSQL role name for the read-only user.
  - parameter: "[`pg_ro_password`](/gateway/configuration/#pg-ro-password)"
    default: Falls back to `pg_password`
    description: Password for the read-only user.
{% endtable %}
<!--vale on-->

## How {{site.base_gateway}} connects to PostgreSQL

{{site.base_gateway}} opens three kinds of database sessions. Each one needs a different set of privileges:

* **Migration session** — The `kong migrations` CLI connects to `pg_database` as `pg_user`. If the schema does not exist, it creates `pg_schema`, switches to it, and runs DDL. The gateway process is not running yet.
* **Runtime session** — The gateway process opens pooled connections to `pg_database` as `pg_user`. Each connection switches to `pg_schema`.
* **Admin CLI session** — A CLI command other than `kong migrations` can also open a database session. Examples are `kong workspace rename`, `kong config db_import`, and `kong config db_export`. This session is a one-off, non-pooled connection, not part of the gateway's connection pool. The command connects to `pg_database` as `pg_user` and switches to `pg_schema`, the same as a runtime session. The command can run whether the gateway process is active or stopped. It can also run statements that the runtime session never runs, including `TRUNCATE` on specific tables and privileges on sequences..

{{site.base_gateway}} connects with a write user (`pg_user`) and, optionally, a read-only user (`pg_ro_user`). {{site.base_gateway}} uses the read-only user only in runtime sessions.

## Role attributes

`LOGIN` is the only attribute that either user needs. The following table lists this minimal set. You can add other attributes, for example `CONNECTION LIMIT`, for your own operational reasons. {{site.base_gateway}} does not require them.

<!--vale off-->
{% table %}
columns:
  - title: Role
    key: role
  - title: Required attribute
    key: attribute
  - title: Notes
    key: notes
rows:
  - role: Write user (`pg_user`)
    attribute: "`LOGIN`"
    notes: Does not need `SUPERUSER`, `CREATEDB`, or `CREATEROLE`.
  - role: Read-only user (`pg_ro_user`)
    attribute: "`LOGIN`"
    notes: Optional. Configure it only when you use a read replica.
{% endtable %}
<!--vale on-->

## Connection privileges

Both the write user and the read-only user need `CONNECT` privilege on `pg_database`. PostgreSQL grants `CONNECT` to `PUBLIC` by default. As a result, this privilege is already open for all roles, unless you revoke it.

## Migration-time privileges

{:.info}
> **Applies to:** Traditional mode with `database = postgres`, and Hybrid mode control plane nodes (`role = control_plane`). Both run `kong migrations` against a real schema.
>
> **Does not apply to:** Traditional db-less mode (`database = off`), because it has no schema to migrate. Hybrid mode data plane nodes (`role = data_plane`) also do not apply. {{site.base_gateway}} config validation forces `database = off` for a data plane node. As a result, the node never connects to PostgreSQL.

Before migration, the write user needs `CREATE` privilege on `pg_database` to create the {{site.base_gateway}} schema.

`kong migrations reset/bootstrap/up/finish` runs the following Data Definition Language (DDL) statements automatically. The following script makes the write user the schema owner (replace `$PG_SCHEMA` with the actual name of `pg_schema`:

```sql
-- kong migrations reset
DROP SCHEMA IF EXISTS $PG_SCHEMA CASCADE;

-- kong migrations bootstrap/up/finish
CREATE SCHEMA IF NOT EXISTS $PG_SCHEMA AUTHORIZATION CURRENT_USER;
GRANT ALL ON SCHEMA $PG_SCHEMA TO CURRENT_USER;
SET SCHEMA $PG_SCHEMA ;
```

After migration, the write user owns the schema and every object the migration session creates in it. Ownership already grants the write user every privilege it needs. As a result, no further `GRANT` is necessary.

## Runtime privileges

{:.info}
> **Applies to:** The same modes as [migration-time privileges](#migration-time-privileges) apply here. Traditional db-less mode loads configuration from a declarative file instead of a database. A Hybrid mode data plane node keeps all state in memory. Neither one opens a database connection.

If the same role runs migrations and runtime, skip this section. Ownership already covers it. If you configure a different write user for runtime, grant it the following privileges:

<!--vale off-->
{% table %}
columns:
  - title: Privilege
    key: privilege
  - title: "On"
    key: object
  - title: Purpose
    key: purpose
rows:
  - privilege: "`USAGE`"
    object: "`pg_schema` schema"
    purpose: Access the {{site.base_gateway}} schema.
  - privilege: "`SELECT`, `INSERT`, `UPDATE`, `DELETE`"
    object: All tables in the schema
    purpose: Admin API CRUD operations, audit logging, and plugin DAO writes.
{% endtable %}
<!--vale on-->

Do not reduce the runtime user to `SELECT` only. {{site.base_gateway}} also writes to the database directly, even when no client calls the Admin API:

<!--vale off-->
{% table %}
columns:
  - title: Write
    key: write
  - title: Commands
    key: commands
  - title: When it happens
    key: when
rows:
  - write: Cache invalidation events between nodes
    commands: "`INSERT`, `DELETE`"
    when: On every configuration change, on each node.
  - write: Data plane heartbeat records
    commands: "`INSERT`, `UPDATE`"
    when: When a data plane node connects to the control plane in Hybrid mode.
  - write: Expired row cleanup
    commands: "`DELETE`"
    when: On a background timer, every 300 seconds by default.
  - write: Lock release
    commands: "`DELETE`"
    when: When {{site.base_gateway}} completes a task that uses a database lock.
  - write: Rate limit counters
    commands: "`INSERT`, `UPDATE`"
    when: "On proxy traffic, when the rate-limiting plugin uses `policy = cluster`."
  - write: Plugin DAO writes
    commands: "`INSERT`, `UPDATE`"
    when: "On proxy traffic through a plugin that persists its own state, for example the `oauth2` plugin, which stores tokens and authorization codes."
  - write: Audit logs (Enterprise)
    commands: "`INSERT`"
    when: "On Admin API activity, when `audit_log = on`."
{% endtable %}
<!--vale on-->

The runtime session never runs `TRUNCATE`. Grant `TRUNCATE` only to the role that runs admin CLI commands. See the next section.

## Admin CLI privileges

{:.info}
> **Applies to:** The same modes as [migration-time privileges](#migration-time-privileges) apply here. `kong config db_import` and `kong config db_export` fail immediately when `database = off`. This rules out Traditional db-less mode. `kong workspace` manages workspace rows that exist only in a database-backed deployment. Hybrid mode data plane nodes also run with `database = off`. As a result, neither command applies to them.

If the same role runs the admin CLI and migrations, skip this section. Ownership already covers it. If you configure a different write user for admin CLI commands, grant it the [runtime privileges](#runtime-privileges), plus the following privileges:

<!--vale off-->
{% table %}
columns:
  - title: Privilege
    key: privilege
  - title: "On"
    key: object
  - title: Purpose
    key: purpose
rows:
  - privilege: "`TRUNCATE`"
    object: Clustering sync tables
    purpose: "`kong workspace` and `kong config db_import` need this privilege. Both commands call `truncate_clustering_sync_version()`."
{% endtable %}
<!--vale on-->

## Read-only user privileges

The read-only user is optional. If you do not point `pg_ro_host` at a read replica, skip this section. Without it, {{site.base_gateway}} never activates the read-only connector. The read-only role does not need to exist.

Only the migration-time write user owns the schema and its tables. As a result, only that user can grant privileges on them. Connect as the migration-time write user or a superuser. Run the following SQL commands to configure the read-only user:

```sql
-- [DCL] Allow connection to the database (default on)
GRANT CONNECT ON DATABASE $PG_DATABASE TO $PG_RO_USER;

-- [DCL] Allow access to the schema
GRANT USAGE ON SCHEMA $PG_SCHEMA  TO $PG_RO_USER;

-- [DCL] Allow SELECT on existing tables created by the migration-time write user
GRANT SELECT ON ALL TABLES IN SCHEMA $PG_SCHEMA  TO $PG_RO_USER;

-- [DCL] Auto-grant SELECT on future tables created by the migration-time write user
ALTER DEFAULT PRIVILEGES FOR ROLE $PG_USER IN SCHEMA $PG_SCHEMA GRANT SELECT ON TABLES TO $PG_RO_USER;
```

Replace the following variables with the actual values:

* `$PG_SCHEMA` with the name of the schema (for example, `public`).
* `$PG_RO_USER` with the value of `pg_ro_user`.
* `$PG_USER` with name of your user (for example, `kong`).
## Minimal setup example

Connect as a PostgreSQL superuser. Create the write user and database before you run migrations:

```sql
-- Create the write user
CREATE ROLE kong WITH LOGIN PASSWORD '$PASSWORD';

-- Create the database, owned by the write user
-- The kong role owns the kong database, so no further GRANT is necessary
CREATE DATABASE kong OWNER kong;
```

Optionally, create a read-only user before you start the gateway:

```sql
-- Create the read-only user
CREATE ROLE kong_ro WITH LOGIN PASSWORD '$PASSWORD';

-- Grant minimal privileges to the read-only user
GRANT CONNECT ON DATABASE kong TO kong_ro;
GRANT USAGE ON SCHEMA public TO kong_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO kong_ro;
ALTER DEFAULT PRIVILEGES FOR ROLE kong IN SCHEMA public GRANT SELECT ON TABLES TO kong_ro;
```
