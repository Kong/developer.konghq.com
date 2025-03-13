---
title: "AI Gateway quickstart script reference"
content_type: reference
layout: reference

products:
  - gateway

tags:
  - ai-gateway

plugins:
  - ai-proxy

min_version:
  gateway: '3.6'

description: "Kong offers an interactive AI quickstart script that launches a demo instance of {{site.base_gateway}} running AI Proxy"

related_resources:
  - text: Kong AI Gateway
    url: /ai-gateway/
---

Kong offers an interactive AI quickstart script that launches a demo instance of {{site.base_gateway}} running AI Proxy:

```sh
curl -Ls https://get.konghq.com/ai | bash
```

The script can either run a {{site.base_gateway}} instance in traditional mode or as a data plane instance for {{site.konnect_short_name}}. You will be prompted to input an API key to configure authentication with an AI provider. 
This key will not be exposed outside of the host machine.

The script creates a service with two routes, and configures the AI Proxy plugin on those routes based on the provider that you specify.

Check out the full script at [https://get.konghq.com/ai](https://get.konghq.com/ai) to see which entities 
it generates, and access all of your routes and services by visiting either [Gateway Manager in {{site.konnect_short_name}}](https://cloud.konghq.com/gateway-manager/) or 
Kong Manager at `https://localhost:8002` in any browser.

{:.note}
> **Note:**
> By default, local models are configured on the endpoint `http://host.docker.internal:11434`,
> which allows {{site.base_gateway}} running in Docker to connect to the host machine. 