{% navtabs "providers" %}
{% navtab "AWS instance" %}

You need:
* A running Redis instance on an [AWS ElastiCache instance](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/auth-iam.html) for Valkey 7.2 or later or ElastiCache for Redis OSS version 7.0 or later
* The [ElastiCache user needs to set "Authentication mode" to "IAM"](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/auth-iam.html#auth-iam-setup)
* The following policy assigned to the IAM user/IAM role that is used to connect to the ElastiCache:
  ```json
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                  "elasticache:Connect"
              ],
              "Resource": [
                  "arn:aws:elasticache:ARN_OF_THE_ELASTICACHE",
                  "arn:aws:elasticache:ARN_OF_THE_ELASTICACHE_USER"
              ]
          }
      ]
  }
  ```

To configure cloud authentication with Redis, add the following parameters to your plugin configuration:

{% if include.name == 'Rate Limiting Advanced' or include.name == 'GraphQL Proxy Cache Advanced' or include.name == 'GraphQL Rate Limiting Advanced' or include.name == 'Proxy Caching Advanced' or include.name == 'Service Protection' %}
```yaml
config:
  strategy: redis
  redis:
    host: $INSTANCE_ADDRESS
    username: $INSTANCE_USERNAME
    port: 6379
    cloud_authentication:
      auth_provider: aws
      aws_cache_name: $AWS_CACHE_NAME
      aws_is_serverless: false
      aws_region: $AWS_REGION
      aws_access_key_id: $AWS_ACCESS_KEY_ID
      aws_secret_access_key: $AWS_ACCESS_SECRET_KEY
```
{% elsif include.name == 'AI Proxy Advanced' or include.name == 'AI RAG Injector' or include.name == 'AI Semantic Cache' or include.name == 'AI Semantic Prompt Guard' or include.name == 'AI Semantic Response Guard' %}
```yaml
config:
  vectordb:
    strategy: redis
    redis:
      host: $INSTANCE_ADDRESS
      username: $INSTANCE_USERNAME
      port: 6379
      cloud_authentication:
        auth_provider: aws
        aws_cache_name: $AWS_CACHE_NAME
        aws_is_serverless: false
        aws_region: $AWS_REGION
        aws_access_key_id: $AWS_ACCESS_KEY_ID
        aws_secret_access_key: $AWS_ACCESS_SECRET_KEY
```

{% elsif include.name == 'OpenID Connect' %}
```yaml
config:
  cluster_cache_strategy: redis
  cluster_cache_redis:
    host: $INSTANCE_ADDRESS
    username: $INSTANCE_USERNAME
    port: 6379
    cloud_authentication:
      auth_provider: aws
      aws_cache_name: $AWS_CACHE_NAME
      aws_is_serverless: false
      aws_region: $AWS_REGION
      aws_access_key_id: $AWS_ACCESS_KEY_ID
      aws_secret_access_key: $AWS_ACCESS_SECRET_KEY
```
{% elsif include.name == 'Datakit' %}
```yaml
config:
  resources:
    cache:
      strategy: redis
      redis:
        host: $INSTANCE_ADDRESS
        username: $INSTANCE_USERNAME
        port: 6379
        cloud_authentication:
          auth_provider: aws
          aws_cache_name: $AWS_CACHE_NAME
          aws_is_serverless: false
          aws_region: $AWS_REGION
          aws_access_key_id: $AWS_ACCESS_KEY_ID
          aws_secret_access_key: $AWS_ACCESS_SECRET_KEY
```
{% elsif include.name == 'Request Callout' or include.name == 'Upstream OAuth' %}
```yaml
config:
  cache:
    strategy: redis
    redis:
      host: $INSTANCE_ADDRESS
      username: $INSTANCE_USERNAME
      port: 6379
      cloud_authentication:
        auth_provider: aws
        aws_cache_name: $AWS_CACHE_NAME
        aws_is_serverless: false
        aws_region: $AWS_REGION
        aws_access_key_id: $AWS_ACCESS_KEY_ID
        aws_secret_access_key: $AWS_ACCESS_SECRET_KEY
```
{% elsif include.name == 'SAML' %}
```yaml
config:
  session_storage: redis
  redis:
    host: $INSTANCE_ADDRESS
    username: $INSTANCE_USERNAME
    port: 6379
    cloud_authentication:
      auth_provider: aws
      aws_cache_name: $AWS_CACHE_NAME
      aws_is_serverless: false
      aws_region: $AWS_REGION
      aws_access_key_id: $AWS_ACCESS_KEY_ID
      aws_secret_access_key: $AWS_ACCESS_SECRET_KEY
```
{% else %}
```yaml
config:
  storage: redis
  storage_config:
    redis:
      host: $INSTANCE_ADDRESS
      username: $INSTANCE_USERNAME
      port: 6379
      cloud_authentication:
        auth_provider: aws
        aws_cache_name: $AWS_CACHE_NAME
        aws_is_serverless: false
        aws_region: $AWS_REGION
        aws_access_key_id: $AWS_ACCESS_KEY_ID
        aws_secret_access_key: $AWS_ACCESS_SECRET_KEY
```
{% endif %}

Replace the following with your actual values:
* `$INSTANCE_ADDRESS`: The ElastiCache instance address.
* `$INSTANCE_USERNAME`: The ElastiCache username with [IAM Auth mode configured](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/auth-iam.html#auth-iam-setup).
* `$AWS_CACHE_NAME`: Name of your AWS ElastiCache instance.
* `$AWS_REGION`: Your AWS ElastiCache instance region.
* `$AWS_ACCESS_KEY_ID`: (Optional) Your AWS access key ID. 
* `$AWS_ACCESS_SECRET_KEY`: (Optional) Your AWS secret access key.
{% endnavtab %}
{% navtab "AWS cluster" %}

You need:
* A running Redis instance on an [AWS ElastiCache cluster](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/auth-iam.html) for Valkey 7.2 or later or ElastiCache for Redis OSS version 7.0 or later
* The [ElastiCache user needs to set "Authentication mode" to "IAM"](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/auth-iam.html#auth-iam-setup)
* The following policy assigned to the IAM user/IAM role that is used to connect to the ElastiCache:
  ```json
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                  "elasticache:Connect"
              ],
              "Resource": [
                  "arn:aws:elasticache:ARN_OF_THE_ELASTICACHE",
                  "arn:aws:elasticache:ARN_OF_THE_ELASTICACHE_USER"
              ]
          }
      ]
  }
  ```

To configure cloud authentication with Redis, add the following parameters to your plugin configuration:

{% if include.name == 'Rate Limiting Advanced' %}
```yaml
config:
  strategy: redis
  redis:
    cluster_nodes:
    - ip: $CLUSTER_ADDRESS
      port: 6379
    username: $CLUSTER_USERNAME
    port: 6379
    cloud_authentication:
      auth_provider: aws
      aws_cache_name: $AWS_CACHE_NAME
      aws_is_serverless: false
      aws_region: $AWS_REGION 
      aws_access_key_id: $AWS_ACCESS_KEY_ID
      aws_secret_access_key: $AWS_ACCESS_SECRET_KEY 
```
{% elsif include.name == 'AI Proxy Advanced' or include.name == 'AI RAG Injector'  or include.name == 'AI Semantic Cache' or include.name == 'AI Semantic Prompt Guard' or include.name == 'AI Semantic Response Guard' %}
```yaml
config:
  vectordb:
    strategy: redis
    redis:
      cluster_nodes:
      - ip: $CLUSTER_ADDRESS
        port: 6379
      username: $CLUSTER_USERNAME
      port: 6379
      cloud_authentication:
        auth_provider: aws
        aws_cache_name: $AWS_CACHE_NAME
        aws_is_serverless: false
        aws_region: $AWS_REGION 
        aws_access_key_id: $AWS_ACCESS_KEY_ID
        aws_secret_access_key: $AWS_ACCESS_SECRET_KEY 
```

{% elsif include.name == 'OpenID Connect' %}
```yaml
config:
  cluster_cache_strategy: redis
  cluster_cache_redis:
    cluster_nodes:
    - ip: $CLUSTER_ADDRESS
      port: 6379
    username: $CLUSTER_USERNAME
    port: 6379
    cloud_authentication:
      auth_provider: aws
      aws_cache_name: $AWS_CACHE_NAME
      aws_is_serverless: false
      aws_region: $AWS_REGION
      aws_access_key_id: $AWS_ACCESS_KEY_ID
      aws_secret_access_key: $AWS_ACCESS_SECRET_KEY
```
{% elsif include.name == 'Datakit' %}
```yaml
config:
  resources:
    cache:
      strategy: redis
      redis:
        cluster_nodes:
        - ip: $CLUSTER_ADDRESS
          port: 6379
        username: $CLUSTER_USERNAME
        port: 6379
        cloud_authentication:
          auth_provider: aws
          aws_cache_name: $AWS_CACHE_NAME
          aws_is_serverless: false
          aws_region: $AWS_REGION
          aws_access_key_id: $AWS_ACCESS_KEY_ID
          aws_secret_access_key: $AWS_ACCESS_SECRET_KEY
```
{% elsif include.name == 'Request Callout' or include.name == 'Upstream OAuth' %}
```yaml
config:
  cache:
    strategy: redis
    redis:
      cluster_nodes:
      - ip: $CLUSTER_ADDRESS
        port: 6379
      username: $CLUSTER_USERNAME
      port: 6379
      cloud_authentication:
        auth_provider: aws
        aws_cache_name: $AWS_CACHE_NAME
        aws_is_serverless: false
        aws_region: $AWS_REGION
        aws_access_key_id: $AWS_ACCESS_KEY_ID
        aws_secret_access_key: $AWS_ACCESS_SECRET_KEY
```
{% elsif include.name == 'SAML' %}
```yaml
config:
  session_storage: redis
  redis:
    cluster_nodes:
    - ip: $CLUSTER_ADDRESS
      port: 6379
    username: $CLUSTER_USERNAME
    port: 6379
    cloud_authentication:
      auth_provider: aws
      aws_cache_name: $AWS_CACHE_NAME
      aws_is_serverless: false
      aws_region: $AWS_REGION
      aws_access_key_id: $AWS_ACCESS_KEY_ID
      aws_secret_access_key: $AWS_ACCESS_SECRET_KEY
```
{% else %}
```yaml
config:
  storage: redis
  storage_config:
    redis:
      cluster_nodes:
      - ip: $CLUSTER_ADDRESS
        port: 6379
      username: $CLUSTER_USERNAME
      port: 6379
      cloud_authentication:
        auth_provider: aws
        aws_cache_name: $AWS_CACHE_NAME
        aws_is_serverless: false
        aws_region: $AWS_REGION
        aws_access_key_id: $AWS_ACCESS_KEY_ID
        aws_secret_access_key: $AWS_ACCESS_SECRET_KEY
```
{% endif %}

Replace the following with your actual values:
* `$CLUSTER_ADDRESS`: The ElastiCache cluster address.
* `$CLUSTER_USERNAME`: The ElastiCache username with [IAM Auth mode configured](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/auth-iam.html#auth-iam-setup).
* `$AWS_CACHE_NAME`: Name of your AWS ElastiCache cluster.
* `$AWS_REGION`: Your AWS ElastiCache cluster region.
* `$AWS_ACCESS_KEY_ID`: (Optional) Your AWS access key ID. 
* `$AWS_ACCESS_SECRET_KEY`: (Optional) Your AWS secret access key.
{% endnavtab %}
{% navtab "Azure instance" %}

You need:
* A running Redis instance on an [Azure Managed Redis instance](https://learn.microsoft.com/en-us/azure/redis/entra-for-authentication) with Entra authentication configured
* Add the [user/service principal/identity to the "Microsoft Entra Authentication Redis user" list](https://learn.microsoft.com/en-us/azure/redis/entra-for-authentication#add-users-or-system-principal-to-your-cache) for the Azure Managed Redis instance

To configure cloud authentication with Redis, add the following parameters to your plugin configuration:

{% if include.name == 'Rate Limiting Advanced' %}
```yaml
config:
  strategy: redis
  redis:
    host: $INSTANCE_ADDRESS
    username: $INSTANCE_USERNAME
    port: 6379
    cloud_authentication:
      auth_provider: azure
      azure_client_id: $AZURE_CLIENT_ID
      azure_client_secret: $AZURE_CLIENT_SECRET
      azure_tenant_id: $AZURE_TENANT_ID
```
{% elsif include.name == 'AI Proxy Advanced' or include.name == 'AI RAG Injector'  or include.name == 'AI Semantic Cache' or include.name == 'AI Semantic Prompt Guard' or include.name == 'AI Semantic Response Guard' %}
```yaml
config:
  vectordb:
    strategy: redis
    redis:
      host: $INSTANCE_ADDRESS
      username: $INSTANCE_USERNAME
      port: 6379
      cloud_authentication:
        auth_provider: azure
        azure_client_id: $AZURE_CLIENT_ID
        azure_client_secret: $AZURE_CLIENT_SECRET
        azure_tenant_id: $AZURE_TENANT_ID
```

{% elsif include.name == 'OpenID Connect' %}
```yaml
config:
  cluster_cache_strategy: redis
  cluster_cache_redis:
    host: $INSTANCE_ADDRESS
    username: $INSTANCE_USERNAME
    port: 6379
    cloud_authentication:
      auth_provider: azure
      azure_client_id: $AZURE_CLIENT_ID
      azure_client_secret: $AZURE_CLIENT_SECRET
      azure_tenant_id: $AZURE_TENANT_ID
```
{% elsif include.name == 'Datakit' %}
```yaml
config:
  resources:
    cache:
      strategy: redis
      redis:
        host: $INSTANCE_ADDRESS
        username: $INSTANCE_USERNAME
        port: 6379
        cloud_authentication:
          auth_provider: azure
          azure_client_id: $AZURE_CLIENT_ID
          azure_client_secret: $AZURE_CLIENT_SECRET
          azure_tenant_id: $AZURE_TENANT_ID
```
{% elsif include.name == 'Request Callout' or include.name == 'Upstream OAuth' %}
```yaml
config:
  cache:
    strategy: redis
    redis:
      host: $INSTANCE_ADDRESS
      username: $INSTANCE_USERNAME
      port: 6379
      cloud_authentication:
        auth_provider: azure
        azure_client_id: $AZURE_CLIENT_ID
        azure_client_secret: $AZURE_CLIENT_SECRET
        azure_tenant_id: $AZURE_TENANT_ID
```
{% elsif include.name == 'SAML' %}
```yaml
config:
  session_storage: redis
  redis:
    host: $INSTANCE_ADDRESS
    username: $INSTANCE_USERNAME
    port: 6379
    cloud_authentication:
      auth_provider: azure
      azure_client_id: $AZURE_CLIENT_ID
      azure_client_secret: $AZURE_CLIENT_SECRET
      azure_tenant_id: $AZURE_TENANT_ID
```
{% else %}
```yaml
config:
  storage: redis
  storage_config:
    redis:
      host: $INSTANCE_ADDRESS
      username: $INSTANCE_USERNAME
      port: 6379
      cloud_authentication:
        auth_provider: azure
        azure_client_id: $AZURE_CLIENT_ID
        azure_client_secret: $AZURE_CLIENT_SECRET
        azure_tenant_id: $AZURE_TENANT_ID
```
{% endif %}

Replace the following with your actual values:
* `$INSTANCE_ADDRESS`: The Azure Managed Redis instance address.
* `$INSTANCE_USERNAME`: The object (principal) ID of the Principal/Identity with essential access.
* `$AZURE_CLIENT_ID`: The client ID of the Principal/Identity.
* `$AZURE_CLIENT_SECRET`: (Optional) The client secret of the Principal/Identity. 
* `$AZURE_TENANT_ID`: (Optional) The tenant ID of the Principal/Identity.

{% endnavtab %}
{% navtab "Azure cluster" %}

You need:
* A running Redis instance on an [Azure Managed Redis cluster](https://learn.microsoft.com/en-us/azure/redis/entra-for-authentication) with Entra authentication configured
* Add the [user/service principal/identity to the "Microsoft Entra Authentication Redis user" list](https://learn.microsoft.com/en-us/azure/redis/entra-for-authentication#add-users-or-system-principal-to-your-cache) for the Azure Managed Redis instance

To configure cloud authentication with Redis, add the following parameters to your plugin configuration:

{% if include.name == 'Rate Limiting Advanced' %}
```yaml
config:
  strategy: redis
  redis:
    cluster_nodes:
    - ip: $CLUSTER_ADDRESS
      port: 6379
    username: $CLUSTER_USERNAME
    port: 6379
    cloud_authentication:
      auth_provider: azure
      azure_client_id: $AZURE_CLIENT_ID
      azure_client_secret: $AZURE_CLIENT_SECRET
      azure_tenant_id: $AZURE_TENANT_ID
```
{% elsif include.name == 'AI Proxy Advanced' or include.name == 'AI RAG Injector'  or include.name == 'AI Semantic Cache' or include.name == 'AI Semantic Prompt Guard' or include.name == 'AI Semantic Response Guard' %}
```yaml
config:
  vectordb:
    strategy: redis
    redis:
      cluster_nodes:
      - ip: $CLUSTER_ADDRESS
        port: 6379
      username: $CLUSTER_USERNAME
      port: 6379
      cloud_authentication:
        auth_provider: azure
        azure_client_id: $AZURE_CLIENT_ID
        azure_client_secret: $AZURE_CLIENT_SECRET
        azure_tenant_id: $AZURE_TENANT_ID
```

{% elsif include.name == 'OpenID Connect' %}
```yaml
config:
  cluster_cache_strategy: redis
  cluster_cache_redis:
    cluster_nodes:
    - ip: $CLUSTER_ADDRESS
      port: 6379
    username: $CLUSTER_USERNAME
    port: 6379
    cloud_authentication:
      auth_provider: azure
      azure_client_id: $AZURE_CLIENT_ID
      azure_client_secret: $AZURE_CLIENT_SECRET
      azure_tenant_id: $AZURE_TENANT_ID
```
{% elsif include.name == 'Datakit' %}
```yaml
config:
  resources:
    cache:
      strategy: redis
      redis:
        cluster_nodes:
        - ip: $CLUSTER_ADDRESS
          port: 6379
        username: $CLUSTER_USERNAME
        port: 6379
        cloud_authentication:
          auth_provider: azure
          azure_client_id: $AZURE_CLIENT_ID
          azure_client_secret: $AZURE_CLIENT_SECRET
          azure_tenant_id: $AZURE_TENANT_ID
```
{% elsif include.name == 'Request Callout' or include.name == 'Upstream OAuth' %}
```yaml
config:
  cache:
    strategy: redis
    redis:
      cluster_nodes:
      - ip: $CLUSTER_ADDRESS
        port: 6379
      username: $CLUSTER_USERNAME
      port: 6379
      cloud_authentication:
        auth_provider: azure
        azure_client_id: $AZURE_CLIENT_ID
        azure_client_secret: $AZURE_CLIENT_SECRET
        azure_tenant_id: $AZURE_TENANT_ID
```
{% elsif include.name == 'SAML' %}
```yaml
config:
  session_storage: redis
  redis:
    cluster_nodes:
    - ip: $CLUSTER_ADDRESS
      port: 6379
    username: $CLUSTER_USERNAME
    port: 6379
    cloud_authentication:
      auth_provider: azure
      azure_client_id: $AZURE_CLIENT_ID
      azure_client_secret: $AZURE_CLIENT_SECRET
      azure_tenant_id: $AZURE_TENANT_ID
```
{% else %}
```yaml
config:
  storage: redis
  storage_config:
    redis:
      cluster_nodes:
      - ip: $CLUSTER_ADDRESS
        port: 6379
      username: $CLUSTER_USERNAME
      port: 6379
      cloud_authentication:
        auth_provider: azure
        azure_client_id: $AZURE_CLIENT_ID
        azure_client_secret: $AZURE_CLIENT_SECRET
        azure_tenant_id: $AZURE_TENANT_ID
```
{% endif %}

Replace the following with your actual values:
* `$CLUSTER_ADDRESS`: The Azure Managed Redis cluster address.
* `$CLUSTER_USERNAME`: The object (principal) ID of the Principal/Identity with essential access.
* `$AZURE_CLIENT_ID`: The client ID of the Principal/Identity.
* `$AZURE_CLIENT_SECRET`: (Optional) The client secret of the Principal/Identity. 
* `$AZURE_TENANT_ID`: (Optional) The tenant ID of the Principal/Identity.

{% endnavtab %}
{% navtab "GCP instance" %}

You need:
* A running Redis instance on an [Google Cloud Memorystore instance](https://cloud.google.com/memorystore/docs/cluster/about-iam-auth)
* Assign the principal to the corresponding role: 
    * [Cloud Memorystore Redis DB Connection User(`roles/redis.dbConnectionUser`)](https://docs.cloud.google.com/memorystore/docs/cluster/about-iam-auth) for Memorystore for Redis Cluster
    * [Memorystore DB Connector User (`roles/memorystore.dbConnectionUser`)](https://docs.cloud.google.com/memorystore/docs/valkey/about-iam-auth) for Memorystore for Valkey

To configure cloud authentication with Redis, add the following parameters to your plugin configuration:

{% if include.name == 'Rate Limiting Advanced' %}
```yaml
config:
  strategy: redis
  redis:
    host: $INSTANCE_ADDRESS
    port: 6379
    cloud_authentication:
      auth_provider: gcp
      gcp_service_account_json: $GCP_SERVICE_ACCOUNT
```
{% elsif include.name == 'AI Proxy Advanced' or include.name == 'AI RAG Injector' or include.name == 'AI Semantic Cache' or include.name == 'AI Semantic Prompt Guard' or include.name == 'AI Semantic Response Guard' %}
```yaml
config:
  vectordb:
    strategy: redis
    redis:
      host: $INSTANCE_ADDRESS
      port: 6379
      cloud_authentication:
        auth_provider: gcp
        gcp_service_account_json: $GCP_SERVICE_ACCOUNT
```

{% elsif include.name == 'OpenID Connect' %}
```yaml
config:
  cluster_cache_strategy: redis
  cluster_cache_redis:
    host: $INSTANCE_ADDRESS
    port: 6379
    cloud_authentication:
      auth_provider: gcp
      gcp_service_account_json: $GCP_SERVICE_ACCOUNT
```
{% elsif include.name == 'Datakit' %}
```yaml
config:
  resources:
    cache:
      strategy: redis
      redis:
        host: $INSTANCE_ADDRESS
        port: 6379
        cloud_authentication:
          auth_provider: gcp
          gcp_service_account_json: $GCP_SERVICE_ACCOUNT
```
{% elsif include.name == 'Request Callout' or include.name == 'Upstream OAuth' %}
```yaml
config:
  cache:
    strategy: redis
    redis:
      host: $INSTANCE_ADDRESS
      port: 6379
      cloud_authentication:
        auth_provider: gcp
        gcp_service_account_json: $GCP_SERVICE_ACCOUNT
```
{% elsif include.name == 'SAML' %}
```yaml
config:
  session_storage: redis
  redis:
    host: $INSTANCE_ADDRESS
    port: 6379
    cloud_authentication:
      auth_provider: gcp
      gcp_service_account_json: $GCP_SERVICE_ACCOUNT
```
{% else %}
```yaml
config:
  storage: redis
  storage_config:
    redis:
      host: $INSTANCE_ADDRESS
      port: 6379
      cloud_authentication:
        auth_provider: gcp
        gcp_service_account_json: $GCP_SERVICE_ACCOUNT
```
{% endif %}

Replace the following with your actual values:
* `$INSTANCE_ADDRESS`: The Memorystore instance address.
* `$GCP_SERVICE_ACCOUNT`: (Optional) The GCP service account JSON.
{% endnavtab %}
{% navtab "GCP cluster" %}

You need:
* A running Redis instance on an [Google Cloud Memorystore cluster](https://cloud.google.com/memorystore/docs/cluster/about-iam-auth)
* Assign the principal to the corresponding role: 
    * [Cloud Memorystore Redis DB Connection User(`roles/redis.dbConnectionUser`)](https://docs.cloud.google.com/memorystore/docs/cluster/about-iam-auth) for Memorystore for Redis Cluster
    * [Memorystore DB Connector User (`roles/memorystore.dbConnectionUser`)](https://docs.cloud.google.com/memorystore/docs/valkey/about-iam-auth) for Memorystore for Valkey

To configure cloud authentication with Redis, add the following parameters to your plugin configuration:

{% if include.name == 'Rate Limiting Advanced' %}
```yaml
config:
  strategy: redis
  redis:
    cluster_nodes:
    - ip: $CLUSTER_ADDRESS
      port: 6379 
    port: 6379
    cloud_authentication:
      auth_provider: gcp
      gcp_service_account_json: $GCP_SERVICE_ACCOUNT
```
{% elsif include.name == 'AI Proxy Advanced' or include.name == 'AI RAG Injector' or include.name == 'AI Semantic Cache' or include.name == 'AI Semantic Prompt Guard' or include.name == 'AI Semantic Response Guard' %}
```yaml
config:
  vectordb:
    strategy: redis
    redis:
      cluster_nodes:
      - ip: $CLUSTER_ADDRESS
        port: 6379 
      port: 6379
      cloud_authentication:
        auth_provider: gcp
        gcp_service_account_json: $GCP_SERVICE_ACCOUNT
```

{% elsif include.name == 'OpenID Connect' %}
```yaml
config:
  cluster_cache_strategy: redis
  cluster_cache_redis:
    cluster_nodes:
    - ip: $CLUSTER_ADDRESS
      port: 6379
    port: 6379
    cloud_authentication:
      auth_provider: gcp
      gcp_service_account_json: $GCP_SERVICE_ACCOUNT
```
{% elsif include.name == 'Datakit' %}
```yaml
config:
  resources:
    cache:
      strategy: redis
      redis:
        cluster_nodes:
        - ip: $CLUSTER_ADDRESS
          port: 6379
        port: 6379
        cloud_authentication:
          auth_provider: gcp
          gcp_service_account_json: $GCP_SERVICE_ACCOUNT
```
{% elsif include.name == 'Request Callout' or include.name == 'Upstream OAuth' %}
```yaml
config:
  cache:
    strategy: redis
    redis:
      cluster_nodes:
      - ip: $CLUSTER_ADDRESS
        port: 6379
      port: 6379
      cloud_authentication:
        auth_provider: gcp
        gcp_service_account_json: $GCP_SERVICE_ACCOUNT
```
{% elsif include.name == 'SAML' %}
```yaml
config:
  session_storage: redis
  redis:
    cluster_nodes:
    - ip: $CLUSTER_ADDRESS
      port: 6379
    port: 6379
    cloud_authentication:
      auth_provider: gcp
      gcp_service_account_json: $GCP_SERVICE_ACCOUNT
```
{% else %}
```yaml
config:
  storage: redis
  storage_config:
    redis:
      cluster_nodes:
      - ip: $CLUSTER_ADDRESS
        port: 6379
      port: 6379
      cloud_authentication:
        auth_provider: gcp
        gcp_service_account_json: $GCP_SERVICE_ACCOUNT
```
{% endif %}

Replace the following with your actual values:
* `$CLUSTER_ADDRESS`: The Memorystore cluster address.
* `$GCP_SERVICE_ACCOUNT`: The GCP service account JSON.
{% endnavtab %}
{% endnavtabs %}