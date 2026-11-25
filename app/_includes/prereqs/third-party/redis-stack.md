Run Redis Stack in a Docker container.
Redis Stack includes the RediSearch and RedisJSON modules that vector search requires.

```sh
docker run -d --name redis-stack -p 6379:6379 redis/redis-stack-server:latest
```
{:data-test-prereq="block"}

Verify that Redis is reachable:

```sh
docker exec redis-stack redis-cli ping
```

The command returns `PONG`.
