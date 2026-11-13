<!---shared with logging plugins: file-log, http-log, loggly, syslog, tcp-log, udp-log --->

{% if include.name == "Syslog" %}
Every request is logged to the System log in [SYSLOG](https://en.wikipedia.org/wiki/Syslog) standard,
with the message component formatted as a JSON object, separated by a new line `\n`.
{% else %}
Every request is logged separately in a JSON object, separated by a new line `\n`.
{% endif %}
<!-- vale off -->
<blockquote class="info">
{% details %}
summary: "**Expand this block to see a sample log object**"
content: |
    ```json
    {
        "response": {
            "size": 1815,
            "headers": {
                "content-type": "application/json",
                "connection": "close",
                "x-kong-llm-model": "openai/gpt-4o-mini",
                "via": "1.1 kong/2.3.0-ai-gateway",
                "x-kong-proxy-latency": "3",
                "content-length": "822",
                "x-kong-upstream-latency": "1155",
                "date": "Fri, 13 Nov 2026 05:03:37 GMT",
                "x-kong-request-id": "85ece81c8acb560be3bff743303c9326",
                "server": "cloudflare"
            },
            "status": 200
        },
        "tries": [
            {
                "balancer_start": 1794546216834,
                "hostname": "api.openai.com",
                "balancer_latency": 0,
                "balancer_latency_ns": 15872,
                "ip": "203.0.113.10",
                "port": 443,
                "balancer_start_ns": 1.7945462168348e+18,
                "target_id": "unknown",
                "keepalive": true
            }
        ],
        "client_ip": "203.0.113.5",
        "request": {
            "headers": {
                "host": "localhost:8000",
                "accept": "*/*",
                "user-agent": "curl/8.7.1",
                "authorization": "REDACTED",
                "content-length": "90",
                "accept-encoding": "identity",
                "content-type": "application/json"
            },
            "method": "POST",
            "size": 242,
            "uri": "/chat/completions",
            "id": "85ece81c8acb560be3bff743303c9326",
            "url": "http://localhost:8000/chat/completions",
            "querystring": {}
        },
        "upstream_uri": "/v1/chat/completions",
        "started_at": 1794546216831,
        "source": "upstream",
        "upstream_status": 200,
        "latencies": {
            "request": 1162,
            "dns": 0.006912,
            "third_party": 0.006912,
            "kong_internal": 6.4322299261473,
            "socket": 0,
            "http_client": 0,
            "receive": 4,
            "redis": 0,
            "client": 0.723712,
            "kong": 3,
            "proxy": 1155
        },
        "ai": {
            "proxy": {
                "usage": {
                    "input_tokens": 13,
                    "input_tokens_details": {
                        "cached_tokens": 0,
                        "audio_tokens": 0
                    },
                    "service_tier": "default",
                    "completion_tokens_details": {
                        "accepted_prediction_tokens": 0,
                        "audio_tokens": 0,
                        "rejected_prediction_tokens": 0,
                        "reasoning_tokens": 0
                    },
                    "output_tokens_details": {
                        "accepted_prediction_tokens": 0,
                        "audio_tokens": 0,
                        "rejected_prediction_tokens": 0,
                        "reasoning_tokens": 0
                    },
                    "output_token_cost": 3.6e-06,
                    "cost": 5.55e-06,
                    "time_to_first_token": 1157,
                    "output_tokens": 6,
                    "time_per_token": 193.33333333333,
                    "total_tokens": 19,
                    "input_token_cost": 1.95e-06,
                    "prompt_tokens": 13,
                    "completion_tokens": 6,
                    "prompt_tokens_details": {
                        "cached_tokens": 0,
                        "audio_tokens": 0
                    }
                },
                "meta": {
                    "model_id": "1bc79836-f5b0-4895-80a1-7486a0e8b439",
                    "response_model": "gpt-4o-mini-2024-07-18",
                    "llm_latency": 1160,
                    "request_mode": "oneshot",
                    "otel_provider_name": "openai",
                    "operation_name": "chat",
                    "plugin_id": "75ff22ed-6245-594b-895f-6a9fa36f4581",
                    "request_model": "gpt-4o-mini",
                    "provider_name": "openai"
                },
                "tried_targets": [
                    {
                        "host": "api.openai.com",
                        "upstream_scheme": "https",
                        "route_type": "llm/v1/chat",
                        "port": 443,
                        "ip": "203.0.113.10",
                        "upstream_uri": "/v1/chat/completions",
                        "provider": "openai",
                        "model": "gpt-4o-mini"
                    }
                ]
            }
        }
    }
    ```
    {:.no-copy-code}
{% enddetails %}
</blockquote>
<!-- vale on -->