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

{% case include.redis_group %}
{% when "brute_force_protection" %}
```yaml
config:
  brute_force_protection:
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
{% when "policy" %}
```yaml
config:
  policy: redis
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
{% when "storage_config" %}
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
{% endcase %}

Replace the following with your actual values:
* `$INSTANCE_ADDRESS`: The ElastiCache instance address.
* `$INSTANCE_USERNAME`: The ElastiCache username with [IAM Auth mode configured](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/auth-iam.html#auth-iam-setup).
* `$AWS_CACHE_NAME`: Name of your AWS ElastiCache instance.
* `$AWS_REGION`: Your AWS ElastiCache instance region.
* `$AWS_ACCESS_KEY_ID`: (Optional) Your AWS access key ID. 
* `$AWS_ACCESS_SECRET_KEY`: (Optional) Your AWS secret access key.
{% endnavtab %}
{% navtab "Azure instance" %}

You need:
* A running Redis instance on an [Azure Managed Redis instance](https://learn.microsoft.com/en-us/azure/redis/entra-for-authentication) with Entra authentication configured
* Add the [user/service principal/identity to the "Microsoft Entra Authentication Redis user" list](https://learn.microsoft.com/en-us/azure/redis/entra-for-authentication#add-users-or-system-principal-to-your-cache) for the Azure Managed Redis instance

To configure cloud authentication with Redis, add the following parameters to your plugin configuration:

{% case include.redis_group %}
{% when "brute_force_protection" %}
```yaml
config:
  brute_force_protection:
    strategy: redis
    redis:
      host: $INSTANCE_ADDRESS
      username: $INSTANCE_USERNAME
      port: 10000
      cloud_authentication:
        auth_provider: azure
        azure_client_id: $AZURE_CLIENT_ID
        azure_client_secret: $AZURE_CLIENT_SECRET
        azure_tenant_id: $AZURE_TENANT_ID
```
{% when "policy" %}
```yaml
config:
  policy: redis
  redis:
    host: $INSTANCE_ADDRESS
    username: $INSTANCE_USERNAME
    port: 10000
    cloud_authentication:
      auth_provider: azure
      azure_client_id: $AZURE_CLIENT_ID
      azure_client_secret: $AZURE_CLIENT_SECRET
      azure_tenant_id: $AZURE_TENANT_ID
```
{% when "storage_config" %}
```yaml
config:
  storage: redis
  storage_config:
    redis:
      host: $INSTANCE_ADDRESS
      username: $INSTANCE_USERNAME
      port: 10000
      cloud_authentication:
        auth_provider: azure
        azure_client_id: $AZURE_CLIENT_ID
        azure_client_secret: $AZURE_CLIENT_SECRET
        azure_tenant_id: $AZURE_TENANT_ID
```
{% endcase %}

Replace the following with your actual values:
* `$INSTANCE_ADDRESS`: The Azure Managed Redis instance address.
* `$INSTANCE_USERNAME`: The object (principal) ID of the Principal/Identity with essential access.
* `$AZURE_CLIENT_ID`: The client ID of the Principal/Identity.
* `$AZURE_CLIENT_SECRET`: (Optional) The client secret of the Principal/Identity. 
* `$AZURE_TENANT_ID`: (Optional) The tenant ID of the Principal/Identity.

{% endnavtab %}
{% navtab "GCP instance" %}

You need:
* A running Redis instance on an [{{ site.google_cloud }} Memorystore instance](https://cloud.google.com/memorystore/docs/cluster/about-iam-auth)
* Assign the principal to the corresponding role: 
    * [Cloud Memorystore Redis DB Connection User(`roles/redis.dbConnectionUser`)](https://docs.cloud.google.com/memorystore/docs/cluster/about-iam-auth) for Memorystore for Redis Cluster
    * [Memorystore DB Connector User (`roles/memorystore.dbConnectionUser`)](https://docs.cloud.google.com/memorystore/docs/valkey/about-iam-auth) for Memorystore for Valkey

To configure cloud authentication with Redis, add the following parameters to your plugin configuration:

{% case include.redis_group %}
{% when "brute_force_protection" %}
```yaml
config:
  brute_force_protection:
    strategy: redis
    redis:
      host: $INSTANCE_ADDRESS
      port: 6379
      cloud_authentication:
        auth_provider: gcp
        gcp_service_account_json: $GCP_SERVICE_ACCOUNT
```
{% when "policy" %}
```yaml
config:
  policy: redis
  redis:
    host: $INSTANCE_ADDRESS
    port: 6379
    cloud_authentication:
      auth_provider: gcp
      gcp_service_account_json: $GCP_SERVICE_ACCOUNT
```
{% when "storage_config" %}
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
{% endcase %}

Replace the following with your actual values:
* `$INSTANCE_ADDRESS`: The Memorystore instance address.
* `$GCP_SERVICE_ACCOUNT`: (Optional) The GCP service account JSON.
{% endnavtab %}
{% navtab "OAuth 2.0" %}

You need:
* An OAuth 2.0 token endpoint that issues access tokens for the `client_credentials` or `password` grant type
* A [Redis deployment](https://redis.io/tutorials/authentication-token-storage-with-redis/) that accepts the issued access token as a bearer credential, either natively or through an OAuth-aware proxy (such as Envoy) placed in front of it

To configure OAuth 2.0 authentication with Redis, add the following parameters to your plugin configuration:

{% case include.redis_group %}
{% when "brute_force_protection" %}
```yaml
config:
  brute_force_protection:
    strategy: redis
    redis:
      host: $INSTANCE_ADDRESS
      port: 6379
      cloud_authentication:
        auth_provider: oauth
        oauth:
          token_endpoint: $OAUTH_TOKEN_ENDPOINT
          grant_type: client_credentials
          client_id: $OAUTH_CLIENT_ID
          client_secret: $OAUTH_CLIENT_SECRET
```
{% when "policy" %}
```yaml
config:
  policy: redis
  redis:
    host: $INSTANCE_ADDRESS
    port: 6379
    cloud_authentication:
      auth_provider: oauth
      oauth:
        token_endpoint: $OAUTH_TOKEN_ENDPOINT
        grant_type: client_credentials
        client_id: $OAUTH_CLIENT_ID
        client_secret: $OAUTH_CLIENT_SECRET
```
{% when "storage_config" %}
```yaml
config:
  storage: redis
  storage_config:
    redis:
      host: $INSTANCE_ADDRESS
      port: 6379
      cloud_authentication:
        auth_provider: oauth
        oauth:
          token_endpoint: $OAUTH_TOKEN_ENDPOINT
          grant_type: client_credentials
          client_id: $OAUTH_CLIENT_ID
          client_secret: $OAUTH_CLIENT_SECRET
```
{% endcase %}

Replace the following with your actual values:
* `$INSTANCE_ADDRESS`: The Redis instance or proxy address.
* `$OAUTH_TOKEN_ENDPOINT`: The OAuth 2.0 token endpoint URL used to request access tokens.
* `$OAUTH_CLIENT_ID`: Your OAuth 2.0 client ID.
* `$OAUTH_CLIENT_SECRET`: Your OAuth 2.0 client secret.

{{site.base_gateway}} caches the acquired token for the duration of its validity and refreshes it asynchronously before it expires. 
To use the `password` grant type instead, set `oauth.grant_type` to `password` and also provide `oauth.username` and `oauth.password`.

If your Redis deployment uses ACL-based authentication and needs a username sent alongside the token, also set one of:
* `oauth.redis_username`: A static username to send with `AUTH <username> <token>`.
* `oauth.redis_username_claim`: The name of a claim in the access token (for example, `oid` for Microsoft Entra ID) to derive the username from.

{% endnavtab %}
{% endnavtabs %}
