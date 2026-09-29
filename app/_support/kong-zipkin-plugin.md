---
title: Jaeger protocol support in the Kong Zipkin plugin
content_type: support
published: false
description: The Zipkin plugin supports various open tracing protocols including Jaeger support.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Does the Kong Zipkin plugin support the Jaeger protocol, and if so, how is it configured?
  a: |
    Yes. Set `default_header_type` to `b3` and point `http_endpoint` at your Jaeger collector's `/api/v1/spans` endpoint.
    `header_type` and `default_header_type` are deprecated in favor of `config.propagation`, but remain functional and auto-populate the newer field.
related_resources: []
---

## Jaeger support for Kong Zipkin Plugin

Does the Kong Zipkin Plugin support the Jaeger protocol and if so how is this configured?

The Zipkin plugin supports various open tracing protocols including Jaeger support.

Below is an example config. Ensure the `default_header_type` is set to `b3`. Also, ensure the `http_endpoint` URL is in a similar format to the example pointing to the `/api/v1/spans`.

Note: `header_type` and `default_header_type` are deprecated in favor of `config.propagation`, though they remain fully functional — creating a plugin with these fields still auto-populates the newer, canonical `config.propagation` field.

Example config:

```json
{
	"config": {
		"tags_header": "Zipkin-Tags",
		"include_credential": true,
		"sample_ratio": 1,
		"traceid_byte_count": 16,
		"default_header_type": "b3",
		"default_service_name": "kong",
		"http_endpoint": "http://jaeger_jaeger-collector_1:9411/api/v1/spans",
		"header_type": "preserve",
		"static_tags": null,
		"local_service_name": "kong"
	},
}
```
