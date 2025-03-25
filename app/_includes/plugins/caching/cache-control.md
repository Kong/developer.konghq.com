
When the [`config.cache_control`](./reference/#schema--config-cache-control) configuration option is enabled, 
{{site.base_gateway}} respects request and response `Cache-Control` headers as 
defined by [RFC7234](https://tools.ietf.org/html/rfc7234#section-5.2), with the following exceptions:

* Cache revalidation is not supported, so directives such as `proxy-revalidate` are ignored
* The behavior of `no-cache` is simplified to exclude the entity from being cached entirely
