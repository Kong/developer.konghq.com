---
title: 'Upstream OAuth'
name: 'Upstream OAuth'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Configure {{site.base_gateway}} to obtain an OAuth2 token to consume an upstream API'


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.8'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: upstream-oauth.png

categories:
  - authentication

tags:
  - authentication

search_aliases:
  - upstream-oauth
  - upstream authentication
  - oauth2
related_resources:
  - text: Configure the Upstream OAuth plugin with Kong Identity
    url: /how-to/configure-kong-identity-upstream-oauth/
notes: |
  In Serverless gateways only the `memory` cache strategy is supported.
---

The Upstream OAuth plugin allows {{site.base_gateway}} to support OAuth flows between {{site.base_gateway}} and the upstream API.

The plugin supports storing tokens issued by the IdP in different backend formats.

## How it works

The upstream OAuth2 credential flow works similarly to the [client credentials grant](/plugins/openid-connect/examples/client-credentials/) used by the OpenID Connect plugin. If a cached access token isn't found, {{site.base_gateway}} issues a request to the IdP token endpoint to obtain a new token, which is cached, and then passed to the upstream API via a configurable header (`Authorization` by default).

<!--vale off-->

{% mermaid %}
sequenceDiagram
    autonumber
    participant client as Client <br>(e.g. mobile app)
    participant kong as API Gateway <br>({{site.base_gateway}})
    participant idp as IdP <br>(e.g. Keycloak)
    participant api as 3rd Party API
    activate client
    activate kong
    client->>kong: request to {{site.base_gateway}}
    deactivate client
    activate idp
    kong->>idp: request access token <br>from IdP using <br>client ID and client secret (if IdP auth is set)
    deactivate kong
    idp->>idp: authenticate client
    activate kong
    idp->>kong: return access token
    deactivate idp
    activate api
    kong->>api: request with access token <br>in authorization header
    deactivate kong
    activate kong
    api->>kong: response
    deactivate api
    activate client
    kong->>client: response
    deactivate client
    deactivate kong
{% endmermaid %}

<!--vale on-->


## Authentication methods

This plugin supports the following [authentication methods](/plugins/upstream-oauth/reference/#schema--config-client-auth-method):

* `client_secret_basic`: Send `client_id` and `client_secret` in an `Authorization: Basic` header
* `client_secret_post`: Send `client_id` and `client_secret` as part of the body
* `client_secret_jwt`: Send a JWT signed with the `client_secret` using the client assertion as part of the body

## Caching

The Upstream OAuth plugin caches tokens returned by the IdP.  
Cached entries expire based on the `expires_in` indicated by the IdP in the response to the token endpoint.

Tokens are cached using a hash of all values configured under the [`config.oauth`](/plugins/upstream-oauth/reference/#schema--config-oauth) key.
This means that if two instances of the plugin (for example, configured on different Routes and Gateway Services) use identical values under the `config.oauth` section,
then these will share cached tokens.

### Caching strategies

The plugin supports the following caching [strategies](/plugins/upstream-oauth/reference/#schema--config-cache-strategy):

* `memory`: A locally stored `lua_shared_dict`. The default dictionary, `kong_db_cache`, is also used by other plugins and {{site.base_gateway}} elements to store unrelated database cache entities.
* `redis`: Supports Redis, Redis Cluster, and Redis Sentinel deployments.

{% include plugins/redis-cloud-auth.md %}
