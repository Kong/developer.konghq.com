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
> **Caution**: There are some [limitations for custom plugins](#using-incremental-config-sync-with-custom-plugins) and for 
[rate limiting plugins](#using-incremental-config-sync-with-rate-limiting-plugins) when using incremental config sync. 
Review and adjust your plugin config before enabling this feature.

During setup, set the following value in your [`kong.conf` files](/gateway/manage-kong-conf/) on both Control Planes and Data Planes:

```
incremental_sync = on
```

Or, if you're running {{site.base_gateway}} in Docker, set the following environment variable:
```
export KONG_INCREMENTAL_SYNC=on
```

## Limitations

When using incremental config sync feature with plugins, you may encounter the following limitations.

### Using incremental config sync with custom plugins

When incremental config sync is enabled, the configuration change notification from the Control Plane only triggers an event for changed entities, and doesn't trigger cache updates in Data Plane nodes. 
This causes outdated and inconsistent configuration for [custom plugins](/gateway/entities/plugin/#custom-plugins).

If you are running {{site.base_gateway}} on {{site.konnect_short_name}} or in hybrid mode, you need to adjust your custom plugins to be compatible with incremental config sync.

#### Workaround for custom plugins

To ensure your custom plugin configuration is kept up to date, you must add additional code logic to register the CRUD events for the entities the plugin cares about, and invalidate the relevant cache data.

Add the code at the end of the `init_worker` function for the custom plugin.
For example:


```lua
function _M.init_worker()
  -- ...
  -- ... your original custom code
  -- add the example code below AFTER any custom plugin code
 
  -- Check if worker_events can be registed successfully
  if not (kong.worker_events and kong.worker_events.register) then
    return
  end

  -- Check the deployment mode and incremental sync feature is enabled
  if kong.configuration.database == "off" and not kong.sync then
    return
  end
  
  -- Do the event registration and force invalidate the corresponding cache
  kong.worker_events.register(
    function(data)
    -- logic to identify what cache need to be invalidated
    kong.cache:invalidate(CACHE_KEY) -- Your plugin logic to invalidate the cache
  end, "crud", "ENTITY_NAME") -- Register the events for entity the plugin cares
  
  -- Repeat the register events for other ENTITIES
  
end
```

### Using incremental config sync with rate limiting plugins

We don't recommend using the `local` strategy for [rate limiting plugins](/plugins/?terms=rate%2520limiting) with incremental config sync.

When [load balancing](/gateway/load-balancing/) across multiple Data Plane nodes, rate limiting is enforced per node. 
With the `local` strategy, rapid configuration updates may cause inconsistencies and potential resets in rate limiting plugins,
impacting performance for API traffic control. 
