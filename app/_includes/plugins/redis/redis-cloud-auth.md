If your plugin uses a Redis datastore, you can authenticate to it with a cloud Redis provider. 
This allows you to seamlessly rotate credentials without relying on static passwords. 

The following providers are supported:
* AWS ElastiCache
* Azure Managed Redis
* Google Cloud Memorystore (with or without Valkey)

{% if include.tier == 'enterprise' %}
Each provider also supports an instance and cluster configuration.
{% endif %}