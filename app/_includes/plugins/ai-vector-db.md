A vector database can be used to store vector embeddings, or numerical representations, of data items. For example, a response would be converted to a numerical representation and stored in the vector database so that it can compare new requests against the stored vectors to find relevant cached items.

The {{include.name}} plugin supports the following vector databases:
* Using `config.vectordb.strategy: redis` and parameters in `config.vectordb.redis`:
  * **[Redis](https://redis.io/docs/latest/stack/search/reference/vectors/)** with Vector Similarity Search (VSS)
  * **[AWS MemoryDB for Redis](https://docs.aws.amazon.com/memorydb/latest/devguide/vector-search-overview.html)** {% new_in 3.12 %}
  * **[Valkey](https://valkey.io/docs/topics/valkeysearch/)** {% new_in 3.14 %}: When you configure `vectordb.strategy: redis`, {{site.base_gateway}} queries the server and checks the server name field. If it detects Valkey request, it automatically uses the Valkey-specific driver.
* Using `config.vectordb.strategy: pgvector` and parameters in `config.vectordb.pgvector`:
  * **[PostgreSQL with pgvector](https://github.com/pgvector/pgvector)** {% new_in 3.10 %}

To learn more about vector databases in {{site.ai_gateway}}, see [Embedding-based similarity matching in Kong AI gateway plugins](/ai-gateway/semantic-similarity/).