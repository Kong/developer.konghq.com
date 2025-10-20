{% if include.slug == "datakit" %}
This is defined via the [`resources.cache.strategy`](./reference/#schema--config-resources-cache-strategy) parameter, which can be one of:

* `redis`: A Redis database. Define properties for this strategy using [`resources.cache.redis`](./reference/#schema--config-resources-cache-redis) or using a [Redis Partial](/gateway/entities/partial/).
* `memory`: A shared dictionary. Define the dictionary name for this strategy using [`resources.cache.memory.dictionary_name`](./reference/#schema--config-resources-cache-memory-dictionary-name).

  The default dictionary, `kong_db_cache`, is also used by other plugins and elements of {{site.base_gateway}} to store unrelated database cache entities.
  Using the `kong_db_cache` dictionary is an easy way to bootstrap and test the plugin, but we don't recommend using it for large-scale installations as significant usage will put pressure on other facets of {{site.base_gateway}}'s database caching operations. 
  In production, we recommend defining a custom `lua_shared_dict` via a custom Nginx template.

Cache entities are stored for a configurable period of time (see [cache TTL](#cache-node)), after which subsequent requests to the same resource will fetch and store the resource again. 

{:.info}
> In [serverless gateways](/serverless-gateways/), only the `memory` strategy is supported.

{% else %}
The {{include.name}} plugin stores cache data in one of two ways, defined via the [`config.strategy`](./reference/#schema--config-strategy) parameter:

* `redis`: A Redis database.
* `memory`: A shared dictionary defined in [`config.memory.dictionary_name`](./reference/#schema--config-memory-dictionary-name).

  The default dictionary, `kong_db_cache`, is also used by other plugins and elements of {{site.base_gateway}} to store unrelated database cache entities.
  Using the `kong_db_cache` dictionary is an easy way to bootstrap and test the plugin, but we don't recommend using it for large-scale installations as significant usage will put pressure on other facets of {{site.base_gateway}}'s database caching operations. 
  In production, we recommend defining a custom `lua_shared_dict` via a custom Nginx template.

Cache entities are stored for a [configurable period of time](./reference/#schema--config-cache-ttl), after which subsequent requests to the same resource will fetch and store the resource again. 

In [Traditional mode](/gateway/traditional-mode/), cache entities can also be [forcefully purged via the Admin API](#managing-cache-entities) prior to their expiration time.

{:.info}
> In [serverless gateways](/serverless-gateways/), only the `memory` strategy is supported.
{% endif %}