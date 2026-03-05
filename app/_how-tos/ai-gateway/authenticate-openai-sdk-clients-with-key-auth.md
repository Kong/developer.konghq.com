---
title: Authenticate OpenAI SDK clients with Key Authentication in {{site.ai_gateway_name}}
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: Key Authentication
    url: /plugins/key-auth/
  - text: Pre-function
    url: /plugins/pre-function/

permalink: /how-to/authenticate-openai-sdk-clients-with-key-auth

description: Use the Pre-function plugin to rewrite OpenAI SDK Bearer tokens into a format compatible with Kong's Key Authentication plugin.

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.6'

plugins:
  - ai-proxy-advanced
  - key-auth
  - pre-function

entities:
  - service
  - route
  - plugin
  - consumer

tags:
  - ai
  - openai
  - authentication
  - ai-sdks

tldr:
  q: How do I use Key Authentication with the OpenAI SDK and {{site.ai_gateway}}?
  a: The OpenAI SDK sends API keys as Bearer tokens in the Authorization header, which Key Auth doesn't recognize. Add a Pre-function plugin to extract the Bearer token and rewrite it into a header that Key Auth expects, then configure Key Auth and AI Proxy Advanced as usual.

tools:
  - deck

prereqs:
  inline:
    - title: OpenAI API Key
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
    - title: Python
      include_content: prereqs/python
      icon_url: /assets/icons/python.svg
    - title: OpenAI SDK
      include_content: prereqs/openai-sdk
      icon_url: /assets/icons/openai.svg
  entities:
    services:
      - example-service
    routes:
      - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---


The [OpenAI SDK](https://platform.openai.com/docs/api-reference/authentication) authenticates by sending `Authorization: Bearer <api-key>` with every request. This behavior is hardcoded in the SDK and can't be changed.

The [Key Auth](/plugins/key-auth/) plugin doesn't inspect the `Authorization` header. It looks for an API key in a configurable header (default: `apikey`), a query parameter, or the request body. This means Key Auth rejects requests from the OpenAI SDK out of the box.

To work around this, you can use the [Pre-function](/plugins/pre-function/) plugin to extract the Bearer token from the `Authorization` header and copy it into the header that Key Auth expects. Pre-function runs before Key Auth in Kong's plugin execution order, so the rewritten header is in place by the time authentication happens.

{:.info}
> If you use the [OpenID Connect](/plugins/openid-connect/) plugin instead of Key Auth, this workaround isn't necessary. OIDC natively inspects Bearer tokens in the `Authorization` header.

## Create a Consumer

Configure a [Consumer](/gateway/entities/consumer/) with a Key Auth credential. The credential value is what OpenAI SDK clients will send as their `api_key`:

{% entity_examples %}
entities:
  consumers:
    - username: openai-client
      keyauth_credentials:
        - key: my-consumer-key
{% endentity_examples %}

## Configure the Pre-function plugin

The [Pre-function](/plugins/pre-function/) plugin intercepts incoming requests and rewrites the `Authorization` header. It extracts the Bearer token and copies it into the `apikey` header, where Key Auth can find it:

{% entity_examples %}
entities:
  plugins:
    - name: pre-function
      config:
        access:
          - |-
            local auth_header = kong.request.get_header("Authorization")
            if auth_header and auth_header:find("^Bearer ") then
              local key = auth_header:sub(8)
              kong.service.request.set_header("apikey", key)
            end
{% endentity_examples %}

## Configure the Key Authentication plugin

Enable [Key Auth](/plugins/key-auth/) on the route. The `key_names` value must match the header name set in the Pre-function code above:

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      config:
        key_names:
          - apikey
{% endentity_examples %}

## Configure the AI Proxy Advanced plugin

Enable [AI Proxy Advanced](/plugins/ai-proxy-advanced/) to proxy authenticated requests to OpenAI. The `auth` block here holds the upstream OpenAI API key, which is separate from the Consumer's Key Auth credential:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        targets:
          - route_type: llm/v1/chat
            auth:
              header_name: Authorization
              header_value: Bearer ${openai_api_key}
            model:
              provider: openai
              name: gpt-4o
              options:
                max_tokens: 512
                temperature: 1.0
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

## Validate

Create a test script to verify the full authentication flow. The script uses the OpenAI Python SDK, pointing at your {{site.base_gateway}} Route with the Consumer's Key Auth credential as the API key.
```bash
cat <<EOF > test_openai.py
from openai import OpenAI

kong_url = "http://localhost:8000"
kong_route = "anything"

client = OpenAI(
    api_key="my-consumer-key",
    base_url=f"{kong_url}/{kong_route}"
)

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": "Say hello."}]
)

print(response.choices[0].message.content)
EOF
```
{: data-deployment-topology="on-prem" data-test-step="block" }
```bash
cat <<EOF > test_openai.py
from openai import OpenAI
import os

kong_url = os.environ['KONNECT_PROXY_URL']
kong_route = "anything"

client = OpenAI(
    api_key="my-consumer-key",
    base_url=f"{kong_url}/{kong_route}"
)

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": "Say hello."}]
)

print(response.choices[0].message.content)
EOF
```
{: data-deployment-topology="konnect" data-test-step="block" }

Run the script:
```bash
python test_openai.py
```

If authentication is configured correctly, you'll see the model's response printed to the terminal.

To confirm that Key Auth is actually enforcing access, create a second script with an invalid key:
```bash
cat <<EOF > test_openai_wrong_key.py
from openai import OpenAI

kong_url = "http://localhost:8000"
kong_route = "anything"

client = OpenAI(
    api_key="wrong-key",
    base_url=f"{kong_url}/{kong_route}"
)

try:
    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": "Say hello."}]
    )
    print(response.choices[0].message.content)
except Exception as e:
    print(f"Expected error: {e}")
EOF
```
{: data-deployment-topology="on-prem" data-test-step="block" }
```bash
cat <<EOF > test_openai_wrong_key.py
from openai import OpenAI
import os

kong_url = os.environ['KONNECT_PROXY_URL']
kong_route = "anything"

client = OpenAI(
    api_key="wrong-key",
    base_url=f"{kong_url}/{kong_route}"
)

try:
    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": "Say hello."}]
    )
    print(response.choices[0].message.content)
except Exception as e:
    print(f"Expected error: {e}")
EOF
```
{: data-deployment-topology="konnect" data-test-step="block" }

Run the script:
```bash
python test_openai_wrong_key.py
```

This should return a `401 Unauthorized` error, confirming that Kong rejects requests with invalid credentials.