{% include /prereqs/third-party/redis-stack.md %}

Export the Redis host as a variable.
The Policy configuration reads it, and the {{site.ai_gateway}} data plane must be able to reach this host:

```sh
export REDIS_HOST='host.docker.internal'
```

{:.info}
> The example uses `host.docker.internal` because the {{site.ai_gateway}} data plane runs in Docker.
> If your data plane runs elsewhere, set `REDIS_HOST` to the address where it reaches Redis.
> Scripts that you run on your machine connect to Redis at `localhost:6379`.
