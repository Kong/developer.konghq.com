---
title: Compress agent traffic with Headroom using {{site.operator_product_name}}
description: "Deploy Headroom next to your {{ site.ai_gateway }} data plane and use an AIGatewayPolicy to compress large tool results before they reach the LLM."
content_type: how_to

permalink: /operator/konnect/how-to/ai-gateway-headroom/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect

products:
  - operator

works_on:
  - konnect

min_version:
  operator: '2.4'
  ai-gateway: '2.2'

prereqs:
  operator:
    rapid: true
    controllers: [AIGATEWAYDATAPLANE]
    konnect:
      auth: true
  inline:
    - title: OpenAI API key
      include_content: /md/ai-gateway/v2/prereqs/openai
      icon_url: /assets/icons/openai.svg
    - title: "{{ site.ai_gateway_name }} resources"
      include_content: /prereqs/operator/ai-gateway
      icon_url: /assets/icons/kubernetes.svg

tldr:
  q: How do I compress agent traffic with Headroom on an {{ site.ai_gateway }} managed by {{site.operator_product_name}}?
  a: |
    Run a single Headroom instance in the cluster with remote compression enabled and a proxy token.
    Then create an `AIGatewayPolicy` of type `ai-prompt-compressor` with `provider: headroom`, pointing `compressor_url` at Headroom's `/v1/compress` endpoint.
    Keep the AI Policy configuration in a Secret so the proxy token never appears in the custom resource.

related_resources:
  - text: AI Prompt Compressor Policy
    url: /ai-gateway/policies/ai-prompt-compressor/
  - text: AI Policies
    url: /ai-gateway/entities/ai-policy/
  - text: "{{ site.ai_gateway_name }} with {{ site.operator_product_name }}"
    url: /operator/konnect/ai-gateway/
  - text: Headroom documentation
    url: https://docs.headroomlabs.ai/

tags:
  - ai
  - performance

faqs:
  - q: How do Headroom sessions affect compression?
    a: |
      The data plane sends every call to Headroom with a session ID, and Headroom compresses differently depending on what it has already seen in that session. In the example in this guide:

      * **Without the AI Prompt Compressor Policy**: about 16,900 prompt tokens. The LLM received the raw JSON tool result.
      * **First request in a session**: about 4,500 prompt tokens. The LLM received all 400 rows as a compact table.
      * **Same tool result again in the same session**: about 700 prompt tokens. The LLM received a heavily reduced summary with most rows removed.

      Compression can remove information the model needs. For requests where the model must see every value exactly, apply the AI Prompt Compressor Policy to specific AI Models instead of globally, and leave out the AI Models that need the full data.
  - q: What happens when Headroom can't be reached?
    a: |
      `stop_on_error` decides what happens when Headroom can't be reached, rejects the token, or times out:

      * `true` fails the request with `500` and `failed to compress prompts: Failure when calling the Headroom compression service`. Use it while you roll out, so configuration mistakes are visible immediately.
      * `false` forwards the original, uncompressed messages. Switch to it once compression is working, because with a global AI Policy a Headroom outage would otherwise fail every request through the gateway.
---

[Headroom](https://github.com/headroomlabs-ai/headroom) compresses agent traffic: tool results, large JSON payloads, search output, and logs. With the [AI Prompt Compressor Policy](/ai-gateway/policies/ai-prompt-compressor/) set to `provider: headroom`, the {{ site.ai_gateway }} data plane sends each request's messages to Headroom and forwards the compressed messages to the LLM. Headroom decides how much to compress. 

This guide uses the following recommended layout:

- One Headroom `Deployment` with exactly one replica in the same namespace as the data plane. Headroom keeps its sessions in memory in a single process, so the data plane must always reach the same instance.
- Headroom's `/v1/compress` endpoint opened to in-cluster callers and protected by a proxy token.
- The AI Prompt Compressor Policy configuration, including the token, stored in a Kubernetes Secret and referenced from the `AIGatewayPolicy`.

## Deploy Headroom

1. Create a proxy token. The data plane sends it to Headroom on every call:

   ```bash
   export HEADROOM_TOKEN=$(openssl rand -hex 16)
   kubectl create secret generic headroom-token -n kong \
     --from-literal=token="$HEADROOM_TOKEN"
   ```

1. Deploy Headroom and its Service:

   ```bash
   echo '
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: headroom
     namespace: kong
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: headroom
     template:
       metadata:
         labels:
           app: headroom
       spec:
         containers:
           - name: headroom
             image: ghcr.io/headroomlabs-ai/headroom:latest
             args: ["--host", "0.0.0.0", "--port", "8787"]
             env:
               - name: HEADROOM_COMPRESS_ALLOW_REMOTE
                 value: "1"
               - name: HEADROOM_PROXY_TOKEN
                 valueFrom:
                   secretKeyRef:
                     name: headroom-token
                     key: token
             ports:
               - containerPort: 8787
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: headroom
     namespace: kong
   spec:
     selector:
       app: headroom
     ports:
       - port: 8787
         targetPort: 8787
   ' | kubectl apply -f -
   ```

   By default, Headroom only answers `/v1/compress` for loopback callers and returns `404` to everyone else. `HEADROOM_COMPRESS_ALLOW_REMOTE=1` lets the data plane pod call it, and `HEADROOM_PROXY_TOKEN` rejects any caller without the token with `401`.

1. Wait for Headroom to be ready:

   ```bash
   kubectl rollout status deployment/headroom -n kong --timeout=5m
   ```

## Record a baseline

Headroom compresses tool output, JSON, code, and logs. It doesn't compress plain user prose by default, and it leaves blocks under about 500 tokens alone. A short chat message will show no change, so the test request carries a large tool result: 400 structured log entries returned by a `fetch_logs` tool call.

1. Build the request:

   ```bash
   jq -n '[range(400) | {id: ., level: (if . % 7 == 0 then "ERROR" else "INFO" end),
     service: "checkout", latency_ms: ((. * 37) % 900),
     msg: (if . % 7 == 0 then "upstream timeout" else "request completed" end)}]' > logs.json

   jq -n --rawfile logs logs.json '{
     model: "gpt-4o-mini",
     messages: [
       {role: "user", content: "Which service produced errors in these logs?"},
       {role: "assistant", content: null, tool_calls: [{id: "call_1", type: "function",
         function: {name: "fetch_logs", arguments: "{\"window\":\"1h\"}"}}]},
       {role: "tool", tool_call_id: "call_1", content: $logs}
     ]}' > request.json
   ```

1. Send the request before you create the AI Prompt Compressor Policy and note the prompt tokens OpenAI reports:

   ```bash
   curl -s http://$AIGW_HOST:8000/v1/chat/completions \
     -H "Content-Type: application/json" \
     -d @request.json | jq '.usage.prompt_tokens'
   ```

   In this example, this request should use about 16,900 prompt tokens.

## Create the AI Prompt Compressor Policy

1. Store the [AI Policy](/ai-gateway/entities/ai-policy/) configuration in a Secret. {{site.operator_product_name}} reads the whole AI Policy `config` from the Secret key, as YAML or JSON, so the proxy token never appears in the `AIGatewayPolicy`. The `konghq.com/secret=true` label lets {{site.operator_product_name}} read the Secret:

   ```bash
   cat > headroom-config.yaml <<EOF
   provider: headroom
   compressor_url: http://headroom.kong.svc.cluster.local:8787/v1/compress
   timeout: 45000
   keepalive_timeout: 60000
   stop_on_error: true
   log_text_data: false
   headroom:
     proxy_token: ${HEADROOM_TOKEN}
     ssl_verify: false
     session_id_headers:
       - x-claude-code-session-id
       - x-claude-code-agent-id
       - thread-id
       - session-id
   EOF

   kubectl create secret generic headroom-policy-config -n kong \
     --from-file=config.yaml=headroom-config.yaml
   kubectl label secret headroom-policy-config -n kong konghq.com/secret=true
   ```

1. Create the AI Policy and apply it to every AI Model:

   ```bash
   echo '
   apiVersion: aiconfiguration.konghq.com/v1alpha1
   kind: AIGatewayPolicy
   metadata:
     name: headroom-compressor
     namespace: kong
   spec:
     aiGatewayRef:
       type: namespacedRef
       namespacedRef:
         name: my-ai-gateway-cp
     apiSpec:
       name: headroom-compressor
       displayName: Headroom compressor
       type: ai-prompt-compressor
       enabled: Enabled
       global: Enabled
       config:
         type: secretRef
         secretRef:
           name: headroom-policy-config
           key: config.yaml
   ' | kubectl apply -f -
   ```

1. Wait for the AI Policy to be reconciled:

   ```bash
   kubectl wait aigatewaypolicy/headroom-compressor -n kong \
     --for=condition=Programmed=True \
     --timeout=5m
   ```

## Validate

1. Send the same request again, this time with a session header. Use a fresh session ID, because Headroom compresses a repeated tool result more aggressively within the same session:

   ```bash
   curl -s http://$AIGW_HOST:8000/v1/chat/completions \
     -H "Content-Type: application/json" \
     -H "x-claude-code-session-id: $(uuidgen)" \
     -d @request.json | jq '.usage.prompt_tokens'
   ```

   The prompt token count drops from about 16,900 in the baseline to about 4,500.

1. To confirm the savings from Headroom's side, forward Headroom's port and read its statistics:

   ```bash
   kubectl port-forward -n kong deployment/headroom 8787:8787 > /dev/null 2>&1 &
   curl -s http://localhost:8787/stats -H "Authorization: Bearer $HEADROOM_TOKEN" \
     | jq '{compress_calls: .requests.by_provider.compress, tokens_saved: .tokens.saved}'
   ```
