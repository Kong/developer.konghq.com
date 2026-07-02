If your plugin uses a Redis datastore, you can authenticate to it with a cloud Redis provider. This allows you to rotate credentials without relying on static passwords.

The following providers are supported:
* AWS ElastiCache
* Azure Managed Redis
* {{ site.google_cloud }} Memorystore (with or without Valkey)

Each provider also supports an instance and cluster configuration.