Some clients, including MCP (Model Context Protocol) clients that follow the [MCP authorization specification](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization), need to know which authorization server protects an API before they can request a token.

[RFC 9728](https://www.rfc-editor.org/rfc/rfc9728) (OAuth 2.0 Protected Resource Metadata) solves this by letting a resource server advertise itself, including which authorization servers protect it and what scopes it supports, at a well-known URI that clients can discover automatically.

When you configure [`config.protected_resource_metadata`]({{ include.schema_page | default: "/plugins/openid-connect/reference/#schema--config-protected-resource-metadata" }}), the OIDC {{ include.type }}:
* Serves an RFC 9728 metadata document at a well-known URI, with no authentication required.
* Rejects a request with no bearer token with a `401 Unauthorized` response instead of `403 Forbidden`, and adds a `resource_metadata` attribute, and optionally a `scope` attribute, to its `WWW-Authenticate` header, so clients that receive a challenge can locate the metadata document.

{:.info}
> Configuring this setting only advertises protected resource metadata and adds it to unauthorized responses.
It doesn't change how the OIDC {{ include.type }} authenticates requests, and the authorization server URLs you configure here aren't validated against `config.issuer`.

### Well-known metadata endpoint

By default, the OIDC {{ include.type }} derives the metadata document's path from [`config.protected_resource_metadata.resource`]({{ include.schema_page | default: "/plugins/openid-connect/reference/#schema--config-protected-resource-metadata-resource" }}) by appending `/.well-known/oauth-protected-resource` to its path component. For example:

* `resource`: `https://api.example.com/mcp`
* Metadata document served at: `https://api.example.com/mcp/.well-known/oauth-protected-resource`

To serve the document at a different path, set [`config.protected_resource_metadata.metadata_endpoint`]({{ include.schema_page | default: "/plugins/openid-connect/reference/#schema--config-protected-resource-metadata-metadata-endpoint" }}).

{{ include.gateway }} intercepts requests to this path before any authentication logic runs:
* `GET` requests receive a `200` response with the metadata document as a JSON body (`Content-Type: application/json`, `Cache-Control: no-store`).
The document always includes `resource`, and includes `authorization_servers` and `scopes_supported` when they're configured.
* Requests using any other method receive a `405` response with an `Allow: GET` header.

For example, with `resource` set to `https://api.example.com/mcp`:

```sh
curl -s https://api.example.com/mcp/.well-known/oauth-protected-resource
```

The response is the metadata document, and doesn't require an `Authorization` header since a client fetches it before it has a token:

```json
{
  "resource": "https://api.example.com/mcp",
  "authorization_servers": ["https://idp.example.com"],
  "scopes_supported": ["openid", "profile"]
}
```
{:.no-copy-code}

{:.info}
> {{ include.gateway }} doesn't handle CORS for the metadata endpoint.
If MCP or browser-based clients need to fetch the metadata document cross-origin, add the {{ include.cors }} to the same route.

### WWW-Authenticate header

When a request is rejected with a `401 Unauthorized` response, the OIDC {{ include.type }} adds a `resource_metadata` attribute to the `WWW-Authenticate` header, pointing to the well-known metadata endpoint.
If [`config.protected_resource_metadata.scopes_supported`]({{ include.schema_page | default: "/plugins/openid-connect/reference/#schema--config-protected-resource-metadata-scopes-supported" }}) is set, the header also includes a `scope` attribute listing the supported scopes.
This only applies to `401` responses.

For example, a request without a bearer token:

```sh
curl -s -i https://api.example.com/mcp
```

Returns a `401` response whose `WWW-Authenticate` header carries the discovery information:

```
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Bearer realm="idp.example.com", resource_metadata="https://api.example.com/mcp/.well-known/oauth-protected-resource", scope="openid profile", error="invalid_token"

{"message":"Unauthorized"}
```
{:.no-copy-code}

{% unless include.hide_examples %}
See the [Set up protected resource metadata](/plugins/openid-connect/examples/protected-resource-metadata/) example for a full configuration.
{% endunless %}
