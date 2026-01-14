---
title: "Incremental configuration sync"
description: "Use incremental configuration sync to send only the changed entity configuration to Data Plane nodes instead of sending the entire configuration set."
content_type: reference
layout: reference
products:
    - gateway

tools:
    - admin-api
    - konnect-api
    - deck
    - kic
    - terraform

related_resources:
  - text: Hybrid mode
    url: /gateway/hybrid-mode/
  - text: Deployment topologies
    url: /gateway/deployment-topologies/
  - text: Data Plane hosting options
    url: /gateway/topology-hosting-options/
  - text: Incremental config sync blog
    url: https://konghq.com/blog/product-releases/incremental-config-sync-tech-preview
  

tags:
  - hybrid-mode

works_on:
  - on-prem
  - konnect

breadcrumbs:
    - /gateway/
---

In [Hybrid mode](/gateway/hybrid-mode/), whenever you make changes to [{{site.base_gateway}} entity](/gateway/entities/) configuration on the Control Plane, it immediately triggers a cluster-wide update of all Data Plane configurations. 
In these updates, {{site.base_gateway}} sends the entire configuration set to the Data Planes. The bigger your configuration set is, the more time it takes to send and process, and the more memory is consumed proportional to the configuration size. This can result in latency spikes and loss in throughput for high-traffic Data Planes under certain conditions.

You can enable incremental configuration sync to address this issue. 
When entity configuration changes, instead of sending the entire configuration set for each change, {{site.base_gateway}} only sends the parts of the configuration that have changed. 

<!--vale off-->
{% mermaid %}
flowchart TD

A[Client]
B(<img src="/assets/icons/gateway.svg" style="max-height:20px"/> Kong Control Plane)
C(<img src="/assets/icons/gateway.svg" style="max-height:20px"/> Kong Data Plane)
D(<img src="/assets/icons/gateway.svg" style="max-height:20px"/> Kong Data Plane)
E[Client]
F(<img src="/assets/icons/gateway.svg" style="max-height:20px"/> Kong Control Plane)
G(<img src="/assets/icons/gateway.svg" style="max-height:20px"/> Kong Data Plane)
H(<img src="/assets/icons/gateway.svg" style="max-height:20px"/> Kong Data Plane)

 subgraph id1 [Incremental config sync]
 direction TB

 E --"POST Route config
 1 entity
 A few KB"---> F --"Updated Route config
 1 entity
 A few KB"---> G & H
 end

 subgraph id2 [No incremental config sync]
 direction TB

 A --"POST Route config
 1 entity
 A few KB"---> B --Full Kong config
 30k entities
 30MB---> C & D

 end

style id1 stroke-dasharray:3,rx:10,ry:10
style id2 stroke-dasharray:3,rx:10,ry:10

{% endmermaid %}
<!--vale on-->
> _**Figure 1**: In an environment with 30k entities of about 30MB total, sending a `POST` request to update one entity sends the whole 30MB config to every Data Plane. 
With incremental config sync enabled, that same `POST` request only triggers an update of a few KB._

Incremental config sync achieves significant memory savings and CPU savings. 
This means lower total cost of ownership for {{site.base_gateway}} users, shorter config propagation delay, and less impact to proxy latency. 
See our [blog on incremental config sync](https://konghq.com/blog/product-releases/incremental-config-sync-tech-preview) for the performance comparisons.

## Enable incremental config sync

You can enable incremental config sync when installing {{site.base_gateway}} in [hybrid mode](/gateway/hybrid-mode/), or when setting up a {{site.konnect_short_name}} Data Plane.

{:.warning}
> **Caution**: There are some [limitations for custom plugins](#incremental-config-sync-with-custom-plugins) and for 
[rate limiting plugins](#incremental-config-sync-with-rate-limiting-plugins) when using incremental config sync. 
Review and adjust your plugin config before enabling this feature.

During setup, set the following value in your [`kong.conf` files](/gateway/manage-kong-conf/) on both Control Planes and Data Planes:

```
incremental_sync = on
```

Or, if you're running {{site.base_gateway}} in Docker, set the following environment variable:
```
export KONG_INCREMENTAL_SYNC=on
```
## Operational behavior and fallback

You can selectively enable or disable incremental config sync across your control plane and data plane nodes.

### Rolling out incremental config sync to some data planes

Incremental config sync (sync.v2) is a different protocol from the original full sync `sync.v1`. The Lua-based control plane supports both `sync.v1` and `sync.v2` simultaneously.

Each data plane uses the `KONG_INCREMENTAL_SYNC` setting to determine which protocol to use:

* If the environment variable `KONG_INCREMENTAL_SYNC=on`, the data plane attempts incremental config sync (v2).
* If the control plane or data plane does not support or disables incremental config sync, they automatically fall back to full sync (v1).
* You can roll out incremental config sync incrementally by toggling this variable per data plane, no additional changes are required.

{:.warning}
> Direct control plane database writes (outside the Admin API, decK, or Terraform) can cause data planes to treat themselves as up-to-date and skip pulling changes. 
> This is especially likely when using incremental config sync. 
> If this happens, new configuration won't be applied, and valid Routes will return 404 errors.
>
> We recommend the following best practices:
>
> - Avoid direct database modifications; use [supported interfaces](/tools/) (Admin API, decK, Terraform).
> - If unavoidable, clear the DP cache (`/usr/local/kong/dbless.lmdb`) and restart to force a full sync.
> - Restart DPs after imports to receive a fresh snapshot from the CP.

### Rolling back to full sync

To revert a data plane from incremental to full sync, set:

`KONG_INCREMENTAL_SYNC=off`

No restart or configuration purge is required.

### Automatic full sync triggers

Even when incremental config sync is enabled, a full sync will still occur in some cases:

* **Config drift or overflow**:
  * If more than 512 changes occur while a data plane is disconnected from the control plane, a full sync is triggered.
  * If a data plane falls too far behind the control plane, or appears to be ahead (which may indicate data corruption or clock drift), a full sync is triggered.

* **Observability**:
  * The data plane logs the start and completion of each full sync at `info` level.

* **Data handling**:
  * If a full sync fails, the data plane continues to serve the last known good configuration and retries the sync.
  * Database purging is only performed after a successful full sync.

## Handling special cases

When using incremental config sync feature with plugins, you may encounter the following limitations, which will require configuration changes.

### Incremental config sync with custom plugins that use cache data

When incremental config sync is enabled, the behavior for cached entities changes:

* With the standard full sync, the Data Plane emits a `declarative:reconfigure` event when any configuration change occurs. 
The Data Plane flushes all cached data from `kong.cache` to ensure the router, balancer, and plugins can get the correct updated configuration. 
* With incremental sync enabled, the Data Plane only emits a fine-grained CRUD event instead of the `declarative:reconfigure` event. 
This means that if you don't handle the fine grained CRUD event for entities, any custom plugins using cached data will use outdated and inconsistent configuration.

If you are running {{site.base_gateway}} on {{site.konnect_short_name}} or in hybrid mode, and have [custom plugins using cache data](/custom-plugins/daos.lua/#cache-custom-entities),
you need to adjust your custom plugins to be compatible with incremental config sync. If your custom plugin doesn't cache any entities, you don't need to make any changes.

Custom plugins should handle the following [Gateway entities](/gateway/entities/) explicitly:
* Routes
* Services
* Consumers
* Plugins
* Certificates
* CA certificates
* SNIS
* Keys
* Keyring keys
* Other entities defined by plugins

The following example shows how to adjust your custom plugin to handle entity caching with incremental config sync.

#### Register entity UPDATE events

To ensure your custom plugin configuration is kept up to date, you must add additional code logic to register the CRUD events for the entities the plugin cares about, and invalidate the relevant cache data.

In the custom plugin’s `init_worker()` function, register entities' CRUD events to handle the entity update operations:

```lua
function _M.init_worker()

  -- create local event variable
  local worker_events = kong.worker_events

  -- register a callback to update consumers cache
  worker_events.register(function(data)
    -- custom cache invalidate logic here
    -- ...
    -- custom cache logic ends
  end, "crud", "consumers")

  -- register a callback to update ca_certificates cache
  worker_events.register(function(data)
    -- custom cache invalidate logic here
    -- ...
    -- custom cache logic ends
  end, "crud", "ca_certificates")

end
```

In the example above, `worker_events.register()` should contain three parameters:

* The first parameter is the invalidation function, in which the plugin should call `kong.cache:invalidate()` to flush the “dirty” cache data. 
  With that, the plugin can identify the operation (create, update, delete) and figure out which entity is old and which is new.
  That information is then used to calculate the cache key.

  The `data` input parameter for the function has the following structure:
  ```lua
  { 
    entity = {...}, 
    old_entity = {...}, 
    operation = "..."
  }
  ```
* The second parameter must be `crud`, which refers to any change event.
When the entity changes (any of create, update, or delete), the plugin gets the notification and calls the invalidation function.

* The third parameter is the entity name that the plugin wants to flush the cache for, for example, `services`, `routes`, or `consumers`.

#### Invalidate old cache data

Determine the cache key which associates with the cached item. It should be a fixed string or a formatted string by entity. 

When you have the correct cache key, you need to call `cache:invalidate(cache_key)`. 
After this call, the item in cache will be cleared:

```lua
local function username_key(username)
  return string.format("consumer_username:%s", username)
end

local entity = data.old_entity or data.entity
if entity then
    cache:invalidate(username_key(entity.username))
end
```

#### Complete example

The following is a complete example of cache invalidation logic for one plugin, which demonstrates how to invalidate the `custom_id` and `username` for the entity `consumer`:

```lua
local workspaces = require "kong.workspaces"
local kong = kong
local null = ngx.null
local _M = {}

function _M.consumer_field_cache_key(key, value)
  return kong.db.consumers:cache_key(key, value, "consumers")
end


function _M.init_worker()
  -- sanity check
  if kong.configuration.database == "off" or not (kong.worker_events and kong.worker_events.register) then
  if not (kong.worker_events and kong.worker_events.register) then
    return
  end

  -- hybrid mode or db-less mode without rpc will not register events (incremental sync disabled)
  if kong.configuration.database == "off" and not kong.sync then
    return
  end
  -- register the CRUD event for the Consumer entity
  kong.worker_events.register(
    function(data)
      workspaces.set_workspace(data.workspace)

      -- define the key calculation function
      local cache_key = _M.consumer_field_cache_key


      -- log the operation info
      local operation = data.operation
      log("consumer ", operation, ", invalidating cache")


      -- invalidate the cache for old entity
      local old_entity = data.old_entity
      if old_entity then
        if old_entity.custom_id and old_entity.custom_id ~= null and old_entity.custom_id ~= "" then
          kong.cache:invalidate(cache_key("custom_id", old_entity.custom_id))
        end
        if old_entity.username and old_entity.username ~= null and old_entity.username ~= "" then
          kong.cache:invalidate(cache_key("username", old_entity.username))
        end
      end


      -- invalidate the cache for new entity just in case 
      local entity = data.entity
      if entity then
        if entity.custom_id and entity.custom_id ~= null and entity.custom_id ~= "" then
          kong.cache:invalidate(cache_key("custom_id", entity.custom_id))
        end
        if entity.username and entity.username ~= null and entity.username ~= "" then
          kong.cache:invalidate(cache_key("username", entity.username))
        end
      end
    end, "crud", "consumers")
end

return _M
```

#### Do I need to change the plugin code again if I disable the feature?

If you update the plugin code to handle the cache data, then want to disable incremental config syn, you don't need to change the plugin code back.

Looking at the [example](#complete-example) in this doc, the first two conditions can detect the on or off state of incremental config sync. 
When incremental config sync is off, the configuration method goes back to the traditional full sync, where the Data Plane node will flush all the cache data, 
and the plugin doesn't need to do any specific cache handling.

### Incremental config sync with rate limiting plugins

We don't recommend using the `local` strategy for [rate limiting plugins](/plugins/?terms=rate%2520limiting) with incremental config sync.

When [load balancing](/gateway/load-balancing/) across multiple Data Plane nodes, rate limiting is enforced per node. 
With the `local` strategy, rapid configuration updates may cause inconsistencies and potential resets in rate limiting plugins,
impacting performance for API traffic control. 
