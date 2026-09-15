When [`config.cache_by_principal`](./reference/#schema--config-cache-by-principal) is enabled, the {{include.name}} plugin composes its [cache key](#cache-key) from one of the following, in order of precedence:

1. The authenticated [Principal's](/identity/principals/) UUID, if `config.cache_by_principal` is enabled and a Principal is present.
1. The authenticated [Consumer's](/gateway/entities/consumer/) UUID, if one is present.
1. The API's UUID. All callers of that API share one cache entry.