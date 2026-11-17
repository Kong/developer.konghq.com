{{site.ai_gateway}} builds the cache key from the following parts of the request:

* The request method and path
* The query parameters
* The request headers listed in [`config.vary_headers`](/ai-gateway/policies/{{include.slug}}/reference/#schema--config-vary-headers)
* The authenticated AI Consumer, when the request is authenticated
* The authenticated principal, when [`config.cache_by_principal`](/ai-gateway/policies/{{include.slug}}/reference/#schema--config-cache-by-principal) is `true`. See [Cache by Principal](/ai-gateway/policies/{{include.slug}}/examples/cache-by-principal/).
