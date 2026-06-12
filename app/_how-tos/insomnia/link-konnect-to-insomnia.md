---
title: Link a {{ site.konnect_short_name }} to {{ site.data.products.insomnia.name }} 
permalink: /how-to/link-konnect-to-insomnia/

content_type: how_to

products:
  - gateway
  - insomnia
works_on:
  - konnect
tools:
  - deck


tiers:
  insomnia: enterprise

min_version:
  insomnia: '13'

description: Link {{ site.data.products.insomnia.name }} to {{ site.konnect_short_name }} and send requests against a Route in your {{site.base_gateway}} Service.
tags:
  - konnect
  - integrations
prereqs:
  entities:
    services:
      - example-service
    routes:
      - example-route

next_steps:
  - text: Use the Collection Runner in Insomnia
    url: /how-to/use-the-collection-runner/
breadcrumbs:
  - /insomnia/
related_resources:
  - text: "{{ site.konnect_short_name }} integration in {{ site.data.products.insomnia.name }}"
    url: /insomnia/konnect-integration/
  - text: Enterprise
    url: /insomnia/enterprise/
  - text: Data Plane hosting options
    url: /gateway/topology-hosting-options/
tldr:
  q: How do I use {{ site.data.products.insomnia.name }} to send requests against a route hosted on {{ site.konnect_short_name }}?
  a: In {{ site.data.products.insomnia.name }}, link {{ site.konnect_short_name }} using a [Personal Access Token (PAT)](/konnect-api/#personal-access-tokens) and set up proxy URLs for your Gateway Service.  
---

## Link {{ site.data.products.insomnia.name }} to {{ site.konnect_short_name }}

1. In your workspace, open the **Konnect** tab
1. In the **Personal Access Token**, paste the PAT
1. Click **Connect & Sync**

In your workspace, {{ site.data.products.insomnia.name }} now displays the {{ site.konnect_short_name }} tab. Open the tab and click **Sync**. After syncing, {{ site.data.products.insomnia.name }} displays your {{site.base_gateway}} Services under the {{ site.konnect_short_name }}

## Set the Proxy URLs

On first Sync, set the proxy URL for each Gateway Service:

1. From your {{ site.data.products.insomnia.name }} workspace, go to the {{ site.konnect_short_name }} tab
1. Select a Gateway Service: `example service` in this guide.
1. Open the **Base Environment** file
1. Input the proxy URLs for the selected Gateway Service. For `example-service`, set `proxy_host` to `localhost:8000` 

{:.info}
> The proxy URLs depend on the type of control plane you chose. See [Data Plane hosting options](/gateway/topology-hosting-options/) for details.

{{ site.data.products.insomnia.name }} never resets this setup when syncing. If you change the proxy URLs in {{ site.konnect_short_name }}, repeat this setup.

You are now ready to send requests from {{ site.data.products.insomnia.name }} against Routes hosted on {{ site.konnect_short_name }}.

## Validate

1. Select any Route from `example-service`
1. Make sure the URL is `{% raw %}http://{{ _.proxy_host }}/anything{% endraw %}`
1. Click **Send**

In the **Preview** tab, {{ site.data.products.insomnia.name }} displays the following response:

```json
{
	"args": {},
	"data": "",
	"files": {},
	"form": {},
	"headers": {
		"Accept": "*/*",
		"Connection": "keep-alive",
		"Host": "httpbin.konghq.com",
		"User-Agent": "insomnia/13.0.0-beta.0",
		"X-Forwarded-Host": "localhost",
		"X-Forwarded-Path": "/anything",
		"X-Forwarded-Prefix": "/anything",
		"X-Kong-Request-Id": "79f33a281e8c62316c922d0ab4fc0703"
	},
	"json": null,
	"method": "GET",
	"origin": "192.168.97.1",
	"url": "http://localhost/anything"
}
```
{:.no-copy-code}