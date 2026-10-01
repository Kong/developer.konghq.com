A vector database stores and compares vector embeddings—numerical representations of text, prompts, documents, or other content. When you configure semantic features in [AI Models](/ai-gateway/entities/ai-model/) or [AI Policies](/ai-gateway/entities/ai-policy/), embeddings are generated and stored in the vector database so that incoming requests can be compared against the stored vectors to find semantically similar matches. For example, an incoming prompt is embedded and compared against cached prompt keys, model descriptions, document chunks, or allow/deny lists to determine semantic similarity.

{{site.ai_gateway}} semantic features support the following vector databases:

* Using `vectordb.strategy: redis` and parameters in `vectordb.redis`:
  * **[Redis](https://redis.io/docs/latest/develop/ai/search-and-query/vectors/)** with Redis Vector Search
  * **[Redis Cloud](https://redis.io/cloud/)**
  * **[Valkey](https://valkey.io/topics/search/)**: When you configure `vectordb.strategy: redis`, {{site.base_gateway}} queries the server and checks the server name field. If it detects Valkey request, it automatically uses the Valkey-specific driver.
  * Managed Redis with cloud authentication:
    * **AWS ElastiCache** (`auth_provider: aws`)
    * **Azure Managed Redis** (`auth_provider: azure`)
    * **Google Cloud Memorystore** (`auth_provider: gcp`)

    For configuration details, see [Using cloud authentication with Redis](#using-cloud-authentication-with-redis).
* Using `vectordb.strategy: pgvector` and parameters in `vectordb.pgvector`:
  * **[PostgreSQL with pgvector](https://github.com/pgvector/pgvector)**

Configure vector database settings in [AI Models](/ai-gateway/entities/ai-model/) and [AI Policies](/ai-gateway/entities/ai-policy/) to enable semantic similarity features.

### Redis version and module requirements

Kong's semantic features use the Redis Query Engine (RediSearch) to create and search vector indexes, and the Redis JSON data type to store indexed documents. Your Redis or Valkey deployment must support both, or vector index creation fails.

* **Self-hosted Redis**: Use [Redis Open Source 8.0 or later](https://redis.io/blog/redis-8-ga/), which bundles the Redis Query Engine and JSON data type by default, or a distribution that adds them as modules, such as Redis Stack, Redis Enterprise, or Redis Cloud.
* **Self-hosted Valkey**: Use [Valkey 8.1 or later](https://valkey.io/topics/valkey-bundle/) with the `valkey-search` and `valkey-json` modules enabled. A vanilla Valkey build without these modules can't be used for semantic features.
* **AWS ElastiCache**: ElastiCache doesn't support custom Redis modules, so ElastiCache for Redis OSS can't be used for semantic features at any version. Use [ElastiCache for Valkey 8.2 or later](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/vector-search-overview.html), which has vector search built in natively.
* **Azure Managed Redis**: [Enable the RediSearch and RedisJSON modules when you create the instance](https://learn.microsoft.com/en-us/azure/redis/redis-modules). Modules can only be selected at creation time and can't be added afterward.
* **{{site.google_cloud}} Memorystore**: Use [Memorystore for Redis Cluster 8.0 or later](https://docs.cloud.google.com/memorystore/docs/cluster/about-json) or Memorystore for Valkey 8.0 or later, both of which include the required modules automatically. Standard (non-cluster) Memorystore for Redis instances, including the Basic tier, are frozen at Redis 7.2 and don't support RediSearch or the JSON data type, so they can't be used for semantic features.
