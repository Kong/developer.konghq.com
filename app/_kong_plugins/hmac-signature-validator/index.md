---
title: 'HMAC Signature Validator'
name: 'HMAC Signature Validator'

content_type: plugin
tier: enterprise

publisher: kong-inc
description: 'The HMAC Signature Validator plugin verifies the HMAC signature of a request body, such as a webhook signature in a custom header, without authenticating a client.'


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.17'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

tags:
  - security

search_aliases:
  - hmac-signature-validator
  - webhook signature
  - payload signature
  - webhook verification
  - hmac

icon: hmac-signature-validator.png

categories:
   - security

related_resources:
  - text: HMAC Auth plugin
    url: /plugins/hmac-auth/
  - text: Key Auth plugin
    url: /plugins/key-auth/
  - text: Vault entity
    url: /gateway/entities/vault/
  - text: Plugin priority
    url: /gateway/entities/plugin/#plugin-priority
  - text: "{{site.base_gateway}} configuration reference"
    url: /gateway/configuration/

faqs:
  - q: Does the HMAC Signature Validator plugin create a Consumer?
    a: |
      No. The HMAC Signature Validator plugin verifies the request body only.
      It doesn't authenticate a client or set a Consumer.

      To identify a Consumer, add an authentication plugin, such as [Key Auth](/plugins/key-auth/), to the same Route.
  - q: Does the HMAC Signature Validator plugin verify a GET request?
    a: |
      Yes. The HMAC Signature Validator plugin treats a request without a body as a request with an empty body.
      The request needs the signature of the empty string in the signature header.

      To avoid rejecting unsigned requests, limit the `methods` of the Route to the methods that the provider signs.
  - q: Can the HMAC Signature Validator plugin verify a signature with a prefix, such as `sha256=<hex>`?
    a: |
      No. The HMAC Signature Validator plugin reads the whole header value as the signature, so a prefix makes the signature invalid and {{site.base_gateway}} returns a `403` response.
  - q: Can the HMAC Signature Validator plugin verify a chunked request?
    a: |
      Nginx buffers the whole body of a chunked request before the HMAC Signature Validator plugin runs.
      Nginx applies [`nginx_http_client_max_body_size`](/gateway/configuration/#nginx-http-client-max-body-size) to a chunked request while it reads the body, and returns a `413` response when the body exceeds the limit.
      To also cap the body that the HMAC Signature Validator plugin accepts, set [`max_body_size`](/plugins/hmac-signature-validator/reference/#schema--config-max-body-size).
  - q: Why does a base64 signature fail with the hex signature format in the HMAC Signature Validator plugin?
    a: |
      The HMAC Signature Validator plugin decodes the signature header with the encoding that [`signature_format`](/plugins/hmac-signature-validator/reference/#schema--config-signature-format) sets, and rejects the request when decoding fails.
      Set the format to the encoding that the provider uses, `hex` or `base64`.
  - q: How does the HMAC Signature Validator plugin know which HMAC algorithm to use?
    a: |
      The signature doesn't name its algorithm, so you must set [`algorithm`](/plugins/hmac-signature-validator/reference/#schema--config-algorithm) to the digest that the provider uses.
      The plugin rejects a signature whose decoded length differs from the digest length, before it reads the body.
  - q: How is the HMAC Signature Validator plugin different from `validate_request_body` in the HMAC Auth plugin?
    a: |
      The `validate_request_body` option of the [HMAC Auth plugin](/plugins/hmac-auth/) compares a SHA-256 hash of the body, computed without a key, with the `Digest` header.

      The HMAC Signature Validator plugin computes a keyed HMAC of the body with a shared secret, so only a sender that knows the secret can produce a valid signature.
---

The HMAC Signature Validator plugin verifies the HMAC signature of a request body, such as the signature that a webhook provider sends in a custom header.
The plugin computes the HMAC of the exact body with a shared secret, and compares it with the signature in the header.
{{site.base_gateway}} rejects a request that has a missing or invalid signature and returns a `403` response, so the request never reaches the upstream.

The plugin verifies the body only.
It doesn't authenticate a client or set a Consumer.
It fits providers that sign the body with one shared secret and don't send a username or other client identifier.

To authenticate a Consumer instead, use the [HMAC Auth plugin](/plugins/hmac-auth/).
That plugin verifies request headers that the client signs with a per-Consumer credential, and it checks the request date.
It can't verify a provider's signature of the request body.

## Use cases

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Verify a hex-encoded signature](/plugins/hmac-signature-validator/examples/verify-hex-signature/)"
    description: "Verify an HMAC-SHA256 signature in a custom header, encoded as hex."
  - use_case: "[Verify a base64-encoded signature](/plugins/hmac-signature-validator/examples/verify-base64-signature/)"
    description: "Verify an HMAC-SHA256 signature in the `X-Shopify-Hmac-SHA256` header, encoded as base64, as Shopify webhooks send it."
  - use_case: "[Store the shared secret in a Vault](/plugins/hmac-signature-validator/examples/use-vault-reference-for-secret/)"
    description: "Reference the shared secret from a Vault instead of entering it in the plugin configuration."
{% endtable %}
<!--vale on-->

## How it works

The HMAC Signature Validator plugin runs in the `access` [phase](/gateway/entities/plugin/#plugin-contexts) of the request.
For each request, the plugin:

1. Reads the header that [`signature_header`](/plugins/hmac-signature-validator/reference/#schema--config-signature-header) names.
1. Decodes the header value with the [`signature_format`](/plugins/hmac-signature-validator/reference/#schema--config-signature-format), and checks that the decoded length matches the digest of the [`algorithm`](/plugins/hmac-signature-validator/reference/#schema--config-algorithm).
1. Reads the request body, up to [`max_body_size`](/plugins/hmac-signature-validator/reference/#schema--config-max-body-size).
1. Computes the HMAC of the body with the shared secret, and compares it with the signature in constant time.
1. Rejects the request when the two values differ.
1. When the values match, removes the signature header, unless you set [`hide_signature_header`](/plugins/hmac-signature-validator/reference/#schema--config-hide-signature-header) to `false`.
1. Proxies the request.

The following diagram shows the checks in order, and the status that each failed check returns:

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant sender as Sender
    participant kong as {{site.base_gateway}} <br>(HMAC Signature Validator)
    participant upstream as Upstream service

    sender->>kong: Request with a signature header
    kong->>kong: Read and decode the signature header
    alt If header is missing, <br>repeated, or the wrong length
        kong-->>sender: 403
    end
    kong->>kong: Read the request body
    alt If body is larger <br>than max_body_size
        kong-->>sender: 413
    end
    kong->>kong: Compute the HMAC of the body <br>with the shared secret
    alt If shared secret is not available
        kong-->>sender: 500
    end
    kong->>kong: Compare the HMAC with the signature
    alt If values differ
        kong-->>sender: 403
    else If values match
        kong->>upstream: Proxy the request
        upstream->>kong: Response
        kong->>sender: Response
    end
{% endmermaid %}
<!--vale on-->

### Requests without a body

The HMAC Signature Validator plugin verifies every request, including a request without a body, such as `GET`.
It treats a request without a body as a request with an empty body, so the signature header must carry the HMAC of the empty string.
It doesn't skip any method, because skipping `GET` would let a sender bypass the check.

Some providers send unsigned `GET`, `HEAD`, or `OPTIONS` requests, for example to check an endpoint or to answer a CORS preflight.
The plugin rejects these requests.
Limit the `methods` of the Route to the methods that the provider signs, or serve the unsigned path from a Route without the plugin.

## Combine with an authentication plugin

The HMAC Signature Validator plugin has a higher [priority](/gateway/entities/plugin/#plugin-priority) than authentication plugins such as [Key Auth](/plugins/key-auth/), [OAuth 2.0 Introspection](/plugins/oauth2-introspection/), and [mTLS Auth](/plugins/mtls-auth/), so it runs first.
{{site.base_gateway}} rejects any request without a valid signature before an authentication plugin looks up a Consumer or calls an identity provider.

A provider webhook usually can't send credentials, so add an authentication plugin only when the sender can present one as well.
The following configuration requires both a valid API key and a valid signature on a Route:

```yaml
_format_version: "3.0"
services:
  - name: orders-service
    url: http://orders.example.com
    routes:
      - name: orders-webhook
        paths:
          - /orders
        plugins:
          - name: key-auth
            config:
              key_names:
              - apikey
          - name: hmac-signature-validator
            config:
              signature_header: X-Signature-SHA256
              algorithm: hmac-sha256
              shared_secret: "{vault://env/WEBHOOK_SHARED_SECRET}"
```

## Shared secret

Store the shared secret in a [Vault](/gateway/entities/vault/) and reference it from the plugin.
We recommend this because a secret that you enter inline is stored in the plugin configuration.

The plugin checks the [`shared_secret`](/plugins/hmac-signature-validator/reference/#schema--config-shared-secret) on each request.
When the secret is empty or is a Vault reference that doesn't resolve, the plugin returns `500` and logs an error.
This keeps a sender from signing with an empty key.

To rotate the secret, update the plugin configuration.
The plugin uses one secret, so requests that the provider signed with the old secret fail until the provider uses the new one.

## Request body size

The plugin reads the whole request body to compute the HMAC.
A body larger than `max_body_size` gets a `413` response, whether or not its signature is valid.

Nginx buffers the whole body before the plugin runs.
This includes chunked requests and HTTP/2 requests without a `Content-Length` header, so the plugin can't reject an oversized body before Nginx buffers it.
To limit what Nginx buffers, set [`nginx_http_client_max_body_size`](/gateway/configuration/#nginx-http-client-max-body-size).
{{site.base_gateway}} doesn't limit the body size by default.

Nginx writes a body larger than [`nginx_http_client_body_buffer_size`](/gateway/configuration/#nginx-http-client-body-buffer-size) to a temporary file, and the plugin reads that file when the body is no larger than `max_body_size`.

While it computes the HMAC, the plugin holds the body in memory, so each concurrent request uses up to `max_body_size` of memory.

## Response codes

The plugin returns `403` because a `401` response needs a `WWW-Authenticate` header, and the plugin doesn't have an authentication challenge.
Missing and invalid signatures return the same status.
Only the message differs.

<!--vale off-->
{% table %}
columns:
  - title: Status
    key: status
  - title: Message
    key: message
  - title: Cause
    key: cause
rows:
  - status: "`403`"
    message: "`signature missing`"
    cause: The signature header is missing or empty.
  - status: "`403`"
    message: "`duplicate signature header`"
    cause: The request has the signature header more than once.
  - status: "`403`"
    message: "`signature invalid`"
    cause: The signature can't be decoded, has the wrong length for the algorithm, or doesn't match the HMAC of the body.
  - status: "`413`"
    message: "`request body too large`"
    cause: The body is larger than `max_body_size`.
  - status: "`431`"
    message: "`request headers too large`"
    cause: The request has more headers than [`lua_max_req_headers`](/gateway/configuration/#lua-max-req-headers), so {{site.base_gateway}} can't check whether the signature header repeats.
  - status: "`500`"
    message: "`An unexpected error occurred`"
    cause: The shared secret isn't available, or {{site.base_gateway}} can't read the body or compute the HMAC. The error log has the cause.
{% endtable %}
<!--vale on-->

## Limitations

* The HMAC Signature Validator plugin doesn't protect against replay.
  The signature covers only the body, so someone who captures a signed request can send it again.
  We recommend that your upstream service check the timestamp that the provider sends, because the plugin doesn't.
* The plugin doesn't parse signatures with a prefix, such as `sha256=<hex>`.
* Each plugin instance verifies one header, with one algorithm and one shared secret.
