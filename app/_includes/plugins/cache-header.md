{{site.base_gateway}} identifies the status of a request's proxy cache behavior via the `X-Cache-Status` header. 
There are several possible values for this header:

* `Miss`: The request could be satisfied in cache, but an entry for the resource was not found in cache, and the request was proxied upstream.
* `Hit`: The request was satisfied and served from cache.
* `Refresh`: The resource was found in cache, but couldn't satisfy the request, due to `Cache-Control` behaviors or from reaching its hardcoded `config.cache_ttl` threshold.
* `Bypass`: The request couldn't be satisfied from cache based on plugin configuration.