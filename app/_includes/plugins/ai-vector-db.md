A vector database can be used to store vector embeddings, or numerical representations, of data items. For example, a response would be converted to a numerical representation and stored in the vector database so that it can compare new requests against the stored vectors to find relevant cached items.

The {{include.name}} plugin supports the following vector databases:
* **[Redis](https://redis.io/docs/latest/stack/search/reference/vectors/)** with Vector Similarity Search (VSS)
* **[PostgreSQL with pgvector](https://github.com/pgvector/pgvector)** {% new_in 3.10 %}
* **[AWS MemoryDB for Redis**](https://docs.aws.amazon.com/memorydb/latest/devguide/vector-search-overview.html)** {% new_in 3.12 %}

To learn more about vector databases in AI Gateway, see [Embedding-based similarity matching in Kong AI gateway plugins](/ai-gateway/semantic-similarity/).sx