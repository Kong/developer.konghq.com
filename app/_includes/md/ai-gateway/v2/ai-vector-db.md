A vector database stores and compares vector embeddings—numerical representations of text, prompts, documents, or other content. When you configure semantic features in [AI Models](/ai-gateway/entities/ai-model/) or [AI Policies](/ai-gateway/entities/ai-policy/), embeddings are generated and stored in the vector database so that incoming requests can be compared against the stored vectors to find semantically similar matches. For example, an incoming prompt is embedded and compared against cached prompt keys, model descriptions, document chunks, or allow/deny lists to determine semantic similarity.

{{site.ai_gateway}} semantic features support the following vector databases:

* Using `vectordb.strategy: redis` and parameters in `vectordb.redis`:
  * **[Redis](https://redis.io/docs/latest/stack/search/reference/vectors/)** with Vector Similarity Search (VSS)
  * **[Redis Cloud](https://redis.io/cloud/)**
  * **[Valkey](https://valkey.io/topics/search/)**: When you configure `vectordb.strategy: redis`, {{site.base_gateway}} queries the server and checks the server name field. If it detects Valkey request, it automatically uses the Valkey-specific driver.
  * Managed Redis with cloud authentication:
    * **AWS ElastiCache** (`auth_provider: aws`)
    * **Azure Managed Redis** (`auth_provider: azure`)
    * **Google Cloud Memorystore** (`auth_provider: gcp`)

    For configuration details, see [Using cloud authentication with Redis](#using-cloud-authentication-with-redis).
* Using `vectordb.strategy: pgvector` and parameters in `vectordb.pgvector`:
  * **[PostgreSQL with pgvector](https://github.com/pgvector/pgvector)** {% new_in 2.0 %}

Configure vector database settings in [AI Models](/ai-gateway/entities/ai-model/) and [AI Policies](/ai-gateway/entities/ai-policy/) to enable semantic similarity features.
