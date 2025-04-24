---
title: Data store
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

description: Learn how to interact with the {{site.base_gateway}} data store in your custom plugin.

tags:
  - custom-plugins

min_version:
  gateway: '3.4'

related_resources:
  - text: Custom plugins
    url: /custom-plugins/
  - text: Custom plugins reference
    url: /custom-plugins/reference/
---

Your custom plugins can interact with {{site.base_gateway}} entities in the [PostgreSQL](http://www.postgresql.org/) data store through classes we refer to as Data Access Objects (DAOs).

All entities in {{site.base_gateway}}, including custom entities are represented by:
* A schema that describes which table the entity relates to in the data store, constraints on its fields such as foreign keys, non-null constraints etc. For custom entities, this is defined in [daos.lua](custom-plugins/daos.lua).
* An instance of the `DAO` class mapping to the database currently in use.
  This class's methods consume the schema and expose methods to insert, update, select, and delete entities of that type.

Both core entities from {{site.base_gateway}} and custom entities from plugins are
available through `kong.db.{entity-name}`. For example:
```lua
local services  = kong.db.services
local routes    = kong.db.routes
local consumers = kong.db.consumers
local plugins   = kong.db.plugins
```

## The DAO Lua API

The DAO class is responsible for the operations executed on a given table in the data store, generally mapping to an entity in {{site.base_gateway}}.
All the underlying supported databases comply to the same interface, thus making the DAO compatible with all of them.

For example, you can use the following code to insert a [Gateway Service](/gateway/entities/service/) and a [plugin](/gateway/entities/plugin/):
```lua
local inserted_service, err = kong.db.services:insert({
  name = "httpbin",
  url  = "https://httpbin.konghq.com",
})

local inserted_plugin, err = kong.db.plugins:insert({
  name    = "key-auth",
  service = inserted_service,
})
```

For a real-life example of the DAO being used in a plugin, see the [Key-Auth plugin source code](https://github.com/Kong/kong/blob/master/kong/plugins/key-auth/handler.lua).