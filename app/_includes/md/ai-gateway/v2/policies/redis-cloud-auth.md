If your Policy uses a Redis datastore, you can authenticate to it with a cloud Redis provider.
This allows you to seamlessly rotate credentials without relying on static passwords.

The following providers are supported:
* AWS ElastiCache
* Azure Managed Redis
* {{ site.google_cloud }} Memorystore (with or without Valkey)
