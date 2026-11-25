Run Redis Stack in a Docker container.
The AI RAG Injector Policy requires the RediSearch and RedisJSON modules, which Redis Stack includes.

```sh
docker run -d --name redis-stack -p 6379:6379 redis/redis-stack-server:latest
```

Verify that Redis is reachable:

```sh
docker exec redis-stack redis-cli ping
```

The command returns `PONG`.

{:.info}
> If your {{site.ai_gateway}} data plane runs in Docker, it reaches Redis at `host.docker.internal:6379`.
> Use that host in the Policy configuration. Scripts that you run on your machine use `localhost:6379`.
