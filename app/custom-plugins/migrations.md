---
title: Migration modules
content_type: reference
layout: reference

breadcrumbs:
  - /custom-plugins/
  - /custom-plugins/reference/

products:
    - gateway

works_on:
    - konnect
    - on-prem

description: Learn how to create migration modules to create database tables to store custom entities and update them for new plugin versions.

tags:
  - custom-plugins

related_resources:
  - text: Custom plugins
    url: /custom-plugins/
  - text: Custom plugins reference
    url: /custom-plugins/reference/
  - text: Data store
    url: /custom-plugins/data-store/
---

The `{plugin-name}/migrations` folder is used to:
* Create tables for custom entities
* Update tables for new plugin versions

The folder should contain:
* An `init.lua` file, to reference the migrations to perform
* At least one migration file, to define the migrations to perform

## init.lua
The initial version of your `migrations/init.lua` file will point to a single migration.

While there is no strict rule for naming your migration files, there is a convention that the
initial one is prefixed by `000`, the next one by `001`, and so on.

If the first migration is named `000_base_my_plugin.lua`, the `init.lua` file should like this:
```lua
return {
  "000_base_my_plugin",
}
```

### Multiple migrations

Sometimes it is necessary to introduce changes after a version of a plugin has already been
released. A new functionality might be needed. A database table row might need changing.

When this happens, you must create a new migrations file. 
You must not modify the existing migration files once they are published.

Following with our previous example, if we wanted to release a new version of the plugin with changes in the database, we would insert it by adding a file called `<plugin_name>/migrations/001_100_to_110.lua`, and referencing it in `init.lua` like this:
```lua
return {
  "000_base_my_plugin",
  "001_100_to_110",
}
```

In this example, `100` is the previous version of the plugin `1.0.0` and `110` is the version to which plugin is migrated, `1.1.0`.

## Migration file syntax

A migration file is a Lua file which returns a table containing two parts:
* `up` is an optional string of raw SQL statements. 
  These statements are triggered by `kong migrations up`. 
  
  We recommend that all the non-destructive operations, such as creation of new tables and addition of new records, are done on the `up` sections.

* `teardown` is an optional Lua function, which takes a `connector` parameter. 
  The connector can invoke the `query` method to execute SQL queries. 
  These statements are triggered by `kong migrations finish`. 
  
  We recommend that destructive operations, such as removal of data, changing row types, and insertion of new data, are done on the `teardown` sections.

All SQL statements should be written so that they are as reentrant as possible. 
For example, use `DROP TABLE IF EXISTS` instead of `DROP TABLE`, `CREATE INDEX IF NOT EXIST` instead of `CREATE INDEX`, and so on. 
If a migration fails for some reason, it's expected that the first attempt at fixing the problem will be simply re-running the migrations.

{:.warning}
> If your `schema` uses a `unique` constraint, you must set this constraint in the migrations for PostgreSQL.

### Example

The following example shows an initial migration file, `000_base_my_plugin.lua` for example, that creates a new table for the plugin named `my_plugin_table` and an index on the `col1` column.

```lua
return {
  postgres = {
    up = [[
      CREATE TABLE IF NOT EXISTS "my_plugin_table" (
        "id"           UUID                         PRIMARY KEY,
        "created_at"   TIMESTAMP WITHOUT TIME ZONE,
        "col1"         TEXT
      );

      DO $$
      BEGIN
        CREATE INDEX IF NOT EXISTS "my_plugin_table_col1"
                                ON "my_plugin_table" ("col1");
      EXCEPTION WHEN UNDEFINED_COLUMN THEN
        -- Do nothing, accept existing state
      END$$;
    ]],
  }
}
```

The following example shows a subsequent migration file, `001_100_to_110.lua` for example, updates the `my_plugin_table` table for a new version of the plugin. 
It updates the table to add a new `cache_key` column, and drops the `col1` column:

```lua
return {
  postgres = {
    up = [[
      DO $$
      BEGIN
        ALTER TABLE IF EXISTS ONLY "my_plugin_table" ADD "cache_key" TEXT UNIQUE;
      EXCEPTION WHEN DUPLICATE_COLUMN THEN
        -- Do nothing, accept existing state
      END$$;
    ]],
    teardown = function(connector, helpers)
      assert(connector:connect_migrations())
      assert(connector:query([[
        DO $$
        BEGIN
          ALTER TABLE IF EXISTS ONLY "my_plugin_table" DROP "col1";
        EXCEPTION WHEN UNDEFINED_COLUMN THEN
          -- Do nothing, accept existing state
        END$$;
      ]]))
    end,
  }
}
```

To see a real-life example, give a look at the [Key-Auth plugin migrations](https://github.com/Kong/kong/tree/master/kong/plugins/key-auth/migrations/).