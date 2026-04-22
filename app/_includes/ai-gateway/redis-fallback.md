When the `redis` strategy is used and a {{site.base_gateway}} node is disconnected from Redis, the plugin will fall back to `local` rate limiting.
This can happen when the Redis server is down or the connection to Redis is broken.
{{site.base_gateway}} keeps the local counters for rate limiting and syncs with Redis once the connection is re-established.
{{site.base_gateway}} will still rate limit, but the {{site.base_gateway}} nodes can't sync the counters. As a result, users will be able
to perform more requests than the limit, but there will still be a limit per node.