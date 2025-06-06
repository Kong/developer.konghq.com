<!---shared with logging plugins: file-log, http-log, loggly, syslog, tcp-log, udp-log --->

{% if include.name == "Syslog" %}
Every request is logged to the System log in [SYSLOG](https://en.wikipedia.org/wiki/Syslog) standard,
with the message component formatted as a JSON object, separated by a new line `\n`.
{% else %}
Every request is logged separately in a JSON object, separated by a new line `\n`.
{% endif %}

<blockquote class="info">
<details>
<summary>
<b>Expand this block to see a sample log object</b>
</summary>

{% capture log %}

```json
{
    "response": {
        "size": 9982,
        "headers": {
            "access-control-allow-origin": "*",
            "content-length": "9593",
            "date": "Thu, 19 Sep 2024 22:10:39 GMT",
            "content-type": "text/html; charset=utf-8",
            "via": "1.1 kong/3.8.0.0-enterprise-edition",
            "connection": "close",
            "server": "gunicorn/19.9.0",
            "access-control-allow-credentials": "true",
            "x-kong-upstream-latency": "171",
            "x-kong-proxy-latency": "1",
            "x-kong-request-id": "2f6946328ffc4946b8c9120704a4a155"
        },
        "status": 200
    },
    "route": {
        "updated_at": 1726782477,
        "tags": [],
        "response_buffering": true,
        "path_handling": "v0",
        "protocols": [
            "http",
            "https"
        ],
        "service": {
            "id": "fb4eecf8-dec2-40ef-b779-16de7e2384c7"
        },
        "https_redirect_status_code": 426,
        "regex_priority": 0,
        "name": "example_route",
        "id": "0f1a4101-3327-4274-b1e4-484a4ab0c030",
        "strip_path": true,
        "preserve_host": false,
        "created_at": 1726782477,
        "request_buffering": true,
        "ws_id": "f381e34e-5c25-4e65-b91b-3c0a86cfc393",
        "paths": [
            "/example-route"
        ]
    },
    "workspace": "f381e34e-5c25-4e65-b91b-3c0a86cfc393",
    "workspace_name": "default",
    "tries": [
        {
            "balancer_start": 1726783839539,
            "balancer_start_ns": 1.7267838395395e+18,
            "ip": "34.237.204.224",
            "balancer_latency": 0,
            "port": 80,
            "balancer_latency_ns": 27904
        }
    ],
    "client_ip": "192.168.65.1",
    "request": {
        "id": "2f6946328ffc4946b8c9120704a4a155",
        "headers": {
            "accept": "*/*",
            "user-agent": "HTTPie/3.2.3",
            "host": "localhost:8000",
            "connection": "keep-alive",
            "accept-encoding": "gzip, deflate"
        },
        "uri": "/example-route",
        "size": 139,
        "method": "GET",
        "querystring": {},
        "url": "http://localhost:8000/example-route"
    },
    "upstream_uri": "/",
    "started_at": 1726783839538,
    "source": "upstream",
    "upstream_status": "200",
    "latencies": {
        "kong": 1,
        "proxy": 171,
        "request": 173,
        "receive": 1
    },
    "service": {
        "write_timeout": 60000,
        "read_timeout": 60000,
        "updated_at": 1726782459,
        "host": "httpbin.konghq.com",
        "name": "example_service",
        "id": "fb4eecf8-dec2-40ef-b779-16de7e2384c7",
        "port": 80,
        "enabled": true,
        "created_at": 1726782459,
        "protocol": "http",
        "ws_id": "f381e34e-5c25-4e65-b91b-3c0a86cfc393",
        "connect_timeout": 60000,
        "retries": 5
    }
}
```
{:.no-copy-code}
{% endcapture %}


{{ log | markdownify }}

</details>
</blockquote>

