
{{site.base_gateway}} can store resource entities in the storage engine longer than the set [`config.cache_ttl`](./reference/#schema--config-cache-ttl) or `Cache-Control` values indicate. 
This allows {{site.base_gateway}} to maintain a cached copy of a resource past its expiration. 

If clients use the `max-age` and `max-stale` headers, they can request stale copies of data.