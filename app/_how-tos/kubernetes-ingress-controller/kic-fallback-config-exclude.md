---
title: "Exclude broken objects with fallback configuration"
description: |
  Remove broken configuration from your {{ site.base_gateway }} configuration automatically
content_type: how_to

permalink: /kubernetes-ingress-controller/fallback-configuration/exclude/

breadcrumbs:
  - /kubernetes-ingress-controller/
  - /kubernetes-ingress-controller/fallback-configuration/

products:
  - kic

tools:
  - kic

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: How do I exclude a broken subset of my {{ site.kic_product_name }} configuration?
  a: Enable the `FallbackConfiguration` feature gate for {{ site.kic_product_name }}

prereqs:
  kubernetes:
    gateway_api: true
    feature_gates: FallbackConfiguration=true
    dump_config: true
  entities:
    services:
      - echo-service

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg

related_resources:
  - text: Fallback configuration overview
    url: /kubernetes-ingress-controller/fallback-configuration/
  - text: "How-To: Backfill broken configuration"
    url: /kubernetes-ingress-controller/fallback-configuration/backfill/
---

## Scenario

In this example, we'll consider a situation where:

1. We have two Routes pointing to the same `Service`. One Route is configured with `KongPlugin`s providing authentication and base rate limiting. Everything works as expected.
2. We add one more rate limiting `KongPlugin` that will be associated with the second Route and a specific `KongConsumer` so that it can be rate limited in a different way than the base rate limiting. But, we forget to associate the `KongConsumer` with the `KongPlugin`. It results in the Route being broken because of duplicated rate limiting plugins.

{% include k8s/content/fallback-configuration/scenario-setup.md %}

## Make a breaking change

Now, let's simulate a situation where we introduce a breaking change to the configuration. We'll remove the `rate-limit-consumer` `KongPlugin` from the `KongConsumer` so that the `route-b` will now have two `rate-limiting` plugins associated with it, which is an invalid {{ site.base_gateway }} configuration:

```bash
kubectl annotate -n kong kongconsumer bob konghq.com/plugins-
```

## Verify the broken route was excluded

This will cause the `route-b` to break as there are two `KongPlugin`s using the same type (`rate-limiting`). We expect `route-b` to be excluded from the configuration.

Let's verify this:

{% validation request-check %}
url: /route-b
status_code: 404
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

The results should look like this:

```text
{
  "message":"no Route matched with those values",
  "request_id":"209a6b14781179103528093188ed4008"
}%
```
{:.no-copy-code}

### Inspecting diagnostic endpoints

The Route isn't configured because the Fallback Configuration mechanism is excluding the broken `HTTPRoute`.

We can verify this by inspecting the diagnostic endpoint:

```bash
kubectl port-forward -n kong deploy/kong-controller 10256 &
sleep 0.5; curl localhost:10256/debug/config/fallback | jq
```

The results should look like this:

```json
{
  "status": "triggered",
  "brokenObjects": [
    {
      "group": "configuration.konghq.com",
      "kind": "KongPlugin",
      "namespace": "default",
      "name": "rate-limit-consumer",
      "id": "7167315d-58f5-4aea-8aa5-a9d989f33a49"
    }
  ],
  "excludedObjects": [
    {
      "group": "configuration.konghq.com",
      "kind": "KongPlugin",
      "version": "v1",
      "namespace": "default",
      "name": "rate-limit-consumer",
      "id": "7167315d-58f5-4aea-8aa5-a9d989f33a49",
      "causingObjects": [
        "configuration.konghq.com/KongPlugin:default/rate-limit-consumer"
      ]
    },
    {
      "group": "gateway.networking.k8s.io",
      "kind": "HTTPRoute",
      "version": "v1",
      "namespace": "default",
      "name": "route-b",
      "id": "fc82aa3d-512c-42f2-b7c3-e6f0069fcc94",
      "causingObjects": [
        "configuration.konghq.com/KongPlugin:default/rate-limit-consumer"
      ]
    }
  ]
}
```
{:.no-copy-code}

## Verify the working Route is still operational and can be updated

We can also ensure the other `HTTPRoute` is still working:

{% validation request-check %}
url: /route-a
status_code: 404
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

The results should look like this:
```text
Welcome, you are connected to node orbstack.
Running on Pod echo-74c66b778-szf8f.
In namespace default.
With IP address 192.168.194.13.
```

What's more, we're still able to update the correct `HTTPRoute` without any issues. Let's modify `route-a`'s path:

```bash
kubectl patch -n kong httproute route-a --type merge -p '{"spec":{"rules":[{"matches":[{"path":{"type":"PathPrefix","value":"/route-a-modified"}}],"backendRefs":[{"name":"echo","port":1027}]}]}}'
```

Let's verify the updated `HTTPRoute`:

{% validation request-check %}
url: /route-a-modified
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

The results should look like this:

```text
Welcome, you are connected to node orbstack.
Running on Pod echo-74c66b778-szf8f.
In namespace default.
With IP address 192.168.194.13.
```
{:.no-copy-code}

The Fallback Configuration mechanism has successfully isolated the broken `HTTPRoute` and allowed the correct one to be updated.