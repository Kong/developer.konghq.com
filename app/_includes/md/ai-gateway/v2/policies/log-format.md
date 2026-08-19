<!---shared with AI Gateway logging Policies: http-log, file-log --->

Every request is logged separately as a JSON object, separated by a new line `\n`.

When a request is proxied to an LLM service through an [AI Model](/ai-gateway/entities/ai-model/), the log entry also includes an `ai.proxy` object with the provider, model, token usage, cost, and latency for that request.

{% details %}
summary: "**Expand this block to see a sample log object for a proxied LLM request**"
content: |
    ```json
    {
        "workspace": "b4a1e9a2-6b4a-4e91-9c2e-3b6a9d8f1c72",
        "workspace_name": "default",
        "source": "upstream",
        "upstream_uri": "/v1/chat/completions",
        "upstream_status": 200,
        "client_ip": "192.168.65.1",
        "started_at": 1787113201719,
        "tries": [
            {
                "ip": "162.159.140.245",
                "port": 443,
                "hostname": "api.openai.com",
                "balancer_latency": 0,
                "balancer_start": 1787113201722,
                "keepalive": true
            }
        ],
        "request": {
            "id": "9ec9264afbbbad5fe5c64877d92eeb04",
            "uri": "/v1/chat/completions",
            "url": "http://localhost:8000/v1/chat/completions",
            "method": "POST",
            "size": 323,
            "querystring": {},
            "headers": {
                "host": "localhost:8000",
                "user-agent": "curl/8.7.1",
                "content-type": "application/json",
                "content-length": "94",
                "authorization": "REDACTED"
            }
        },
        "response": {
            "status": 200,
            "size": 1845,
            "headers": {
                "content-type": "application/json",
                "content-length": "847",
                "date": "Wed, 19 Aug 2026 04:20:02 GMT",
                "server": "cloudflare",
                "via": "1.1 kong/2.0.2-ai-gateway",
                "x-kong-request-id": "9ec9264afbbbad5fe5c64877d92eeb04",
                "x-kong-proxy-latency": "3",
                "x-kong-upstream-latency": "970",
                "x-kong-llm-model": "openai/gpt-4o",
                "x-ratelimit-remaining-requests": "4999",
                "x-ratelimit-remaining-tokens": "799993",
                "openai-organization": "org-example123456",
                "openai-project": "proj_example7890abcd"
            }
        },
        "latencies": {
            "kong": 3,
            "proxy": 970,
            "request": 976,
            "receive": 3
        },
        "service": {
            "id": "947a4e23-b483-5a65-8165-da9aed24565b",
            "name": "ai-gateway",
            "host": "ai-gateway.upstream.local",
            "port": 80,
            "protocol": "http"
        },
        "route": {
            "id": "8ae36805-da7a-55b9-b056-72bde6bb937d",
            "name": "openai-chat",
            "paths": ["/v1/chat/completions"],
            "methods": ["POST"]
        },
        "ai": {
            "proxy": {
                "tried_targets": [
                    {
                        "route_type": "llm/v1/chat",
                        "provider": "openai",
                        "host": "api.openai.com",
                        "port": 443,
                        "upstream_scheme": "https",
                        "upstream_uri": "/v1/chat/completions",
                        "model": "gpt-4o"
                    }
                ],
                "meta": {
                    "request_mode": "oneshot",
                    "provider_name": "openai",
                    "request_model": "gpt-4o",
                    "response_model": "gpt-4o-2024-08-06",
                    "operation_name": "chat",
                    "llm_latency": 972,
                    "plugin_id": "f3adc007-171c-5519-8763-3a0eef79bde3"
                },
                "usage": {
                    "prompt_tokens": 13,
                    "completion_tokens": 12,
                    "total_tokens": 25,
                    "cost": 0,
                    "time_per_token": 81,
                    "time_to_first_token": 971
                }
            }
        }
    }
    ```
    {:.no-copy-code}
{% enddetails %}

The following table describes the core objects in the log. For a full breakdown of the `ai.*` fields shown in the previous example, see [{{site.ai_gateway}} logs](/ai-gateway/ai-logs/#ai-gateway-logs).

<!--vale off-->
{% table %}
columns:
  - title: Log item
    key: log
  - title: Description
    key: description
rows:
  - log: "`service`"
    description: Properties of the AI Gateway Service associated with the requested Route.
  - log: "`route`"
    description: Properties of the specific Route requested.
  - log: "`request`"
    description: Properties of the request sent by the client.
  - log: "`response`"
    description: Properties of the response sent to the client.
  - log: "`latencies`"
    description: Latency data for the request.
  - log: "`tries`"
    description: A list of iterations made by the load balancer for this request, including each upstream target that was tried.
  - log: "`client_ip`"
    description: The original client IP address.
  - log: "`workspace`"
    description: The UUID of the workspace associated with this request.
  - log: "`upstream_uri`"
    description: The URI, including query parameters, for the configured upstream service.
  - log: "`consumer`"
    description: The authenticated AI Consumer. Only present if authentication is enabled.
  - log: "`started_at`"
    description: The Unix timestamp of when the request started to be processed.
  - log: "`source`"
    description: Indicates whether the response is generated by `kong` or `upstream`.
  - log: "`upstream_status`"
    description: The status code received from the upstream service in the response.
  - log: "`ai`"
    description: |
      Present only for requests proxied to an LLM. Contains provider, model, usage, cost, and cache metrics, keyed by Policy name (for example, `ai.proxy`).
{% endtable %}
<!--vale on-->
