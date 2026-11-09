The {{include.name}} Policy has a priority of 100.
For details, see [AI Policy priority](/ai-gateway/entities/ai-policy/#ai-policy-priority).

Authentication and policies with a higher priority run before the cache.
For example, an unauthenticated request receives a `401` response, and the [IP Restriction Policy](/ai-gateway/policies/ip-restriction/) rejects a denied client even when a cached entry exists.

A [Request Termination Policy](/ai-gateway/policies/request-termination/) has a lower priority, so it runs after the cache.
A request that hits the cache returns the cached response even when it carries the trigger header of the Request Termination Policy.
