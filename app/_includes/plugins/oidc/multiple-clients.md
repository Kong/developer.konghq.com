You can configure the OIDC {{ include.type }} ([`config.client_id`]({{ include.schema_page | default: "/plugins/openid-connect/reference/#schema--config-client-id" }})) and 
client secrets ([`config.client_secret`]({{ include.schema_page | default: "/plugins/openid-connect/reference/#schema--config-client-secret" }})), where the ID and client pairs correspond based on their locations in the array.

For example:

```yaml
config:
  issuer: example-issuer-url
  client_id:
    - my-first-client
    - my-second-client
  client_secret:
    - first-client-secret
    - second-client-secret
```

When making a request, you can specify which client to target to use by including a client ID argument.
For example, after configuring the {{ include.type }} client secrets, you can target a client by name:

```sh
curl -X GET "http://localhost:8000?client_id=my-second-client"
```

Or by its index value (starting with 1):

```sh
curl -X GET "http://localhost:8000?client_id=2"
```

{{ include.gateway }} will look for the client ID in the following locations, in order of precedence:
1. If [`config.client_arg`]({{ include.schema_page | default: "/plugins/openid-connect/reference/#schema--config-client-arg" }}) is set, {{ include.gateway }} checks for that value in the following order: in the request header, URI argument, and body.
1. If `config.client_arg` is not set, {{ include.gateway }} checks for a `client_id` in the following order: in the request header, URI argument, and body.
1. If no client is found in either of those places, {{ include.gateway }} uses the first client ID and client secret pair.

{:.info}
> **Note:** Configuring multiple clients is not possible with the client credentials grant, as the {{ include.type }} always uses the client ID passed directly from the client.
