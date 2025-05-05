The {{include.name}} plugin exposes several [`/{{include.slug}}`](./api/) 
endpoints for cache management through the Kong Admin API.

You can use the Admin API to:
* Look up cache entities
* Delete cache entities
* Purge all caches

To access these endpoints, [enable the plugin](./examples/) first.
The {{include.name}} caching endpoints will appear once the plugin has been enabled.

{:.warning}
> This plugin's API endpoints are not available in [hybrid mode](/gateway/hybrid-mode/). 
The data that this API targets is located on the Data Planes, and Data Planes can't use the Kong Admin API.