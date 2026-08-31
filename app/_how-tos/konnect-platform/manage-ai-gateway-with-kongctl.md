---
title: Manage {{site.ai_gateway}} with kongctl
description: >-
  Create {{site.ai_gateway}} and route an OpenAI chat request through a local
  data plane.
content_type: how_to
permalink: /kongctl/manage-ai-gateway/

breadcrumbs:
  - /kongctl/

products:
  - ai-gateway
  - konnect

works_on:
  - konnect

tools:
  - kongctl

min_version:
  ai-gateway: '2.0'
  kongctl: '1.14'

tags:
  - ai
  - declarative-config
  - openai

tldr:
  q: How do I manage an AI Gateway with kongctl?
  a: |
    Declare the AI Gateway, Model Provider, Model, and data-plane certificate
    in YAML, apply the configuration with kongctl, and connect a data plane.

automated_tests: false

prereqs:
  skip_product: false
  show_works_on: false
  inline:
    - title: "{{site.konnect_product_name}}"
      content: |
        You need a {{site.konnect_short_name}} account and kongctl 1.14 or
        later authenticated with `kongctl login`.
      icon_url: /assets/icons/gateway.svg
    - title: Local tools
      content: |
        Install Docker and OpenSSL. You also need an
        [OpenAI API key](https://platform.openai.com/api-keys).
      icon_url: /assets/icons/ai.svg

related_resources:
  - text: Use kongctl to manage {{site.ai_gateway}}
    url: /ai-gateway/kongctl/
  - text: Declarative configuration with kongctl
    url: /kongctl/declarative/
  - text: kongctl declarative resource reference
    url: /kongctl/supported-resources/#ai-gateway

next_steps:
  - text: Manage additional AI Gateway resources
    url: /ai-gateway/kongctl/
  - text: Learn about kongctl sync
    url: /kongctl/sync/
---

This tutorial creates an {{site.ai_gateway}}, an OpenAI Model Provider and
Model, and a data-plane certificate. You then run a local data plane and send
an OpenAI-compatible chat request through it.

## Create a working directory

Create a directory for the configuration and certificate:

```sh
mkdir kongctl-ai-gateway
```

Change into the directory:

```sh
cd kongctl-ai-gateway
```

Create a certificate directory:

```sh
mkdir certs
```

Generate a self-signed certificate and private key:

```sh
openssl req -new -x509 -nodes -newkey rsa:2048 -days 365 \
  -subj "/CN=openai-llm-data-plane/C=US" \
  -keyout certs/data-plane.key \
  -out certs/data-plane.crt
```

Allow the data-plane container group to read the private key:

```sh
chgrp "$(id -g)" certs/data-plane.key
chmod 640 certs/data-plane.key
```

Keep `certs/data-plane.key` private and out of version control. kongctl sends
only the public certificate to {{site.konnect_short_name}}.

## Declare {{site.ai_gateway}}

Create `ai-gateway.yaml` with the following configuration:

```yaml
_defaults:
  kongctl:
    namespace: openai-llm-example

ai_gateways:
  - ref: openai-llm
    name: openai-llm
    display_name: OpenAI LLM Gateway
    deployment_type: hybrid
    description: Routes OpenAI-compatible chat traffic to OpenAI
    proxy_urls:
      - host: localhost
        port: 8000
        protocol: http
    labels:
      example: openai-llm
    data_plane_certificates:
      - ref: openai-llm-data-plane
        title: openai-llm-data-plane
        description: Local Docker data plane
        cert: !file ./certs/data-plane.crt
    model_providers:
      - ref: openai
        name: openai
        display_name: OpenAI
        type: openai
        config:
          auth:
            type: basic
            headers:
              - name: Authorization
                value: !secret
                  parts:
                    - "Bearer "
                    - !env OPENAI_API_KEY
    models:
      - ref: my-gpt-4o
        name: my-gpt-4o
        display_name: My GPT-4o
        type: model
        formats:
          - type: openai
        config:
          route:
            paths:
              - /v1
            model:
              body_param: model
              values:
                - my-gpt-4o
        targets:
          - name: gpt-4o
            provider: openai
            config:
              type: openai
        policies: []
        capabilities:
          - generate
```

Set your OpenAI API key:

```sh
export OPENAI_API_KEY='YOUR_OPENAI_API_KEY'
```

Preview the changes:

```sh
kongctl diff --mode apply -f ai-gateway.yaml
```

Apply the configuration:

```sh
kongctl apply -f ai-gateway.yaml
```

The `!secret` value is resolved only during execution. The resolved OpenAI
key isn't stored in the configuration or plan.

## Connect the data plane

Read the configuration endpoint from {{site.ai_gateway}}:

```sh
export AIGW_CONTROL_PLANE="$(kongctl get ai-gateway \
  'OpenAI LLM Gateway' --output json --jq \
  '.endpoints.configuration | sub("^https://"; "") | sub(":443$"; "")' \
  --jq-raw-output)"
```

Read the telemetry endpoint:

```sh
export AIGW_TELEMETRY="$(kongctl get ai-gateway \
  'OpenAI LLM Gateway' --output json --jq \
  '.endpoints.telemetry | sub("^https://"; "") | sub(":443$"; "")' \
  --jq-raw-output)"
```

Start a {{site.ai_gateway}} 2.0 data plane:

```sh
docker run --detach --rm --name openai-llm-data-plane \
  --group-add "$(id -g)" \
  --env KONG_ROLE=data_plane \
  --env KONG_DATABASE=off \
  --env KONG_VITALS=off \
  --env KONG_CLUSTER_MTLS=pki \
  --env "KONG_CLUSTER_CONTROL_PLANE=$AIGW_CONTROL_PLANE:443" \
  --env "KONG_CLUSTER_SERVER_NAME=$AIGW_CONTROL_PLANE" \
  --env "KONG_CLUSTER_TELEMETRY_ENDPOINT=$AIGW_TELEMETRY:443" \
  --env "KONG_CLUSTER_TELEMETRY_SERVER_NAME=$AIGW_TELEMETRY" \
  --env KONG_CLUSTER_CERT=/etc/kong/certs/data-plane.crt \
  --env KONG_CLUSTER_CERT_KEY=/etc/kong/certs/data-plane.key \
  --env KONG_LUA_SSL_TRUSTED_CERTIFICATE=system \
  --env KONG_KONNECT_MODE=on \
  --volume "$PWD/certs:/etc/kong/certs:ro" \
  --publish 8000:8000 \
  --publish 8443:8443 \
  kong/kong-ai-gateway:2.0.2
```

Confirm that the data plane connects:

```sh
kongctl get ai-gateway nodes --gateway-name "OpenAI LLM Gateway"
```

## Send a chat request

Send an OpenAI-compatible request through the local proxy:

```sh
curl --no-progress-meter --fail-with-body \
  --request POST http://localhost:8000/v1/chat/completions \
  --header "Accept: application/json" \
  --json '{
    "model": "my-gpt-4o",
    "messages": [
      {"role": "user", "content": "Say this is a test!"}
    ]
  }'
```

A successful response contains a chat completion from `gpt-4o`.

## Clean up

Stop and remove the local data plane:

```sh
docker stop openai-llm-data-plane
```

Delete {{site.ai_gateway}} and its managed child resources:

```sh
kongctl delete -f ai-gateway.yaml
```

Delete the local certificate files when you no longer need them.
