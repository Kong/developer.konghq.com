---
title: Block unauthorized requests in {{site.base_gateway}} with the OPA plugin
permalink: /how-to/block-unauthorized-requests-with-opa/

description: Set up an OPA policy in {{site.base_gateway}} to block unauthorized requests.
content_type: how_to

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

plugins:
  - opa

entities:
  - service
  - route
  - plugin

tags:
    - security
    - opa

tldr:
    q: How can I set up a policy with OPA in {{site.base_gateway}}?
    a: Run an OPA server and create a policy, then enable the [OPA plugin](/plugins/opa/) and specify the `config.opa_host` and `config.opa_path` parameters.
      

tools:
    - deck

prereqs:
  entities:
    services:
      - example-service
    routes:
      - example-route
  inline: 
    - title: OPA server
      content: |
        This tutorial requires an OPA server. You can run a local server for testing:
        1. [Install OPA](https://www.openpolicyagent.org/docs/latest/#1-download-opa).
        2. Run a local server:
           ```sh
           opa run -s
           ```
        3. In a new terminal window, check that the server is running properly:
           ```sh
           curl -i http://localhost:8181
           ```
      icon_url: /assets/icons/opa.svg

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

automated_tests: false
---

## Create a policy file

In this example, we want a policy that states that a request must have a header named `my-secret-header` with the value `open-sesame`. Any request without this header, or with a different value, will return an error.

Create a `.rego` file containing the policy:
```sh
echo 'package example

default allow_boolean := false

allow_boolean if {
	header_present
}

header_present if {
	input.request.http.headers["my-secret-header"] == "open-sesame"
}

' > example.rego
```

## Upload the policy to the OPA server

Use the OPA [Policy API](https://www.openpolicyagent.org/docs/latest/rest-api/#create-or-update-a-policy) to upload the policy file to the local OPA server. This will allow {{site.base_gateway}} to access it.
```sh
curl -i -XPUT localhost:8181/v1/policies/example --data-binary @example.rego
```

You should get a `200 OK` response with an empty object in the response body.

## Create decK environment variables 

We'll use decK environment variables for the `opa_host` and `opa_path` in the OPA plugin configuration. This is because these values typically can vary between environments.

In this tutorial, we're using `host.docker.internal` as our host instead of the `localhost` that OPA is using because {{site.base_gateway}} is running in a container that has a different `localhost` to you.

The `opa_path` value is the [Data API](https://www.openpolicyagent.org/docs/latest/rest-api/#data-api) endpoint for the policy.

```
export DECK_OPA_HOST=host.docker.internal
export DECK_OPA_PATH=/v1/data/example/allow_boolean
```

## Enable the OPA plugin

In this example, we'll enable the plugin globally:

{% entity_examples %}
entities:
  plugins:
    - name: opa
      config:
        opa_host: ${host}
        opa_path: ${path}

variables:
  host:
    value: $OPA_HOST
  path:
    value: $OPA_PATH
{% endentity_examples %}

{:.info}
> **Note:** If your OPA server doesn't use the default `8181` port, you'll need to specify the `config.opa_port` parameter too.

## Validate

To validate that the policy is working, send a request without the required header:

<!--vale off-->
{% validation request-check %}
url: /anything
status_code: 403
method: GET
display_headers: true
{% endvalidation %}
<!--vale on-->

Then try using the correct header with an incorrect value:
<!--vale off-->
{% validation request-check %}
url: /anything
status_code: 403
method: GET
headers:
    - 'my-secret-header: open'
display_headers: true
{% endvalidation %}
<!--vale on-->

In both cases, you should get a `403 Forbidden` response.

Now, send the request with the correct header value:

<!--vale off-->
{% validation request-check %}
url: /anything
status_code: 200
method: GET
headers:
    - 'my-secret-header: open-sesame'
display_headers: true
{% endvalidation %}
<!--vale on-->

You should get a `200 OK` response.