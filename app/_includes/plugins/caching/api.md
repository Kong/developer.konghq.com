The {{include.name}} plugin exposes several [`/{{include.slug}}`](./api/) 
endpoints for cache management through the Kong Admin API.

You can use the Admin API to:
* Look up cache entities
* Delete cache entities
* Purge all caches

To access these endpoints, [enable the plugin](./examples/) first.
The {{include.name}} caching endpoints will appear once the plugin has been enabled.

{:.warning}
> When using the [`memory` caching strategy](./reference/#schema--config-memory) and running the Gateway in [hybrid mode](/gateway/hybrid-mode/), this plugin's API endpoints are not available. 
The data that this API targets is located on the data planes, and data planes can't use the Kong Admin API or {{site.konnect_short_name}} Control Plane API.