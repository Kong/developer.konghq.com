---
title: Enable rate limiting on a service
related_resources:
  - text: How to create rate limiting tiers
    url: https://docs.konghq.com/gateway/api/admin-ee/latest/
  - text: Rate Limiting Advanced plugin
    url: https://docs.konghq.com/hub/kong-inc/rate-limiting-advanced/

plugins:
  - rate-limiting

entities: 
  - service
  - plugin

content_type: tutorial

---

## Prerequisites 

place holder for prerendered prereq instructions that contains: 

* Docker: Docker is used to run a temporary Kong Gateway and database to allow you to run this tutorial
* curl: curl is used to send requests to Kong Gateway . 


{% step title="Install Kong Gateway" %}

Run Kong Gateway with the quickstart script:
```bash
curl -Ls https://get.konghq.com/quickstart | bash -s
```

Once the Kong Gateway is ready, you will see the following message:

```bash
Kong Gateway Ready 
```
{% endstep %}

{% step title="Create a Service" %}

Create a service named `example_service` mapped to the upstream URL `http://httpbin.org` with:

{% entity_example %}
 type: service
 data:
   name: example_service
   url: 'http://httpbin.org'
 formats:
   - admin-api
   - konnect
   - deck
   - terraform
{% endentity_example %}
{% endstep %}

{% step title="Create a Route" %}

Create a route associated with the service we created in the previous step.

Configure the route on the `/mock` path to direct traffic to the `example_service` created earlier.

{% entity_example %}
type: route
data:
  name: example_route
  paths:
    - /example-route
  service:
    name: example_service
formats:
  - admin-api
  - konnect
  - deck
  - terraform
{% endentity_example %}
{% endstep %}

{% step title="Enable the Rate Limiting Plugin on the Service" %}
Install the Rate Limiting plugin on the service and configure a policy of 5 requests per second. 

Note: This setup uses the client's IP for rate limiting if no authentication layer is present.
If an authentication plugin is configured, the consumer is used instead.

{% entity_example %}
type: plugin
data:
  name: rate-limiting
  config:
    second: 5
    policy: local
targets:
  - service
formats:
  - admin-api
  - konnect
  - deck
  - terraform
variables: 
    serviceName|Id: example_service
{% endentity_example %}
{% endstep %}

{% step title="Validate" %}
After configuring the Rate Limiting plugin, you can verify that it was configured correctly and is working, by sending more requests then allowed in the configured time limit.
```bash
for _ in {1..6}
do
  curl http://localhost:8000/example-route/anything/
done
```
After the 5th request, you should receive the following `429` error:

```bash
{ "message": "API rate limit exceeded" }
```
{% endstep %}

{% step title="Teardown" %}
Destroy the Kong Gateway container.

```bash
curl -Ls https://get.konghq.com/quickstart | bash -s -- -d
```
{% endstep %}
