Reset the vector store and remove all ingested data, flush the Redis database:

```shell
docker exec -it redis-stack redis-cli FLUSHALL
```