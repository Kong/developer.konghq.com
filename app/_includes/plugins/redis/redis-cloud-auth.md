If your plugin uses a Redis datastore, you can authenticate to it with a cloud Redis provider, or with an OAuth 2.0 token endpoint. 
This allows you to seamlessly rotate credentials without relying on static passwords. 

The following providers are supported:
* AWS ElastiCache
* Azure Managed Redis
* {{ site.google_cloud }} Memorystore (with or without Valkey)
* OAuth 2.0 {% new_in 3.16 %}, using the `client_credentials` or `password` grant type

{% if include.tier == 'enterprise' %}
Each cloud provider also supports an instance and cluster configuration.
{% endif %}