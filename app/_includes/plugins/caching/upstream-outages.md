If an upstream is unreachable, {{site.base_gateway}} can serve cache data instead of returning an error. 
However, this requires managing stale cache data.

We recommend setting a high [`storage_ttl`](./reference/#schema--config-storage-ttl) value measured in hours or days to store stale data in the cache.  
If an upstream service becomes unavailable, you can increase the [`cache_ttl`](./reference/#schema--config-cache-ttl) value to treat the stale data as fresh.  
This allows {{site.base_gateway}} to serve previously cached data to clients before attempting to connect to the unavailable upstream service.