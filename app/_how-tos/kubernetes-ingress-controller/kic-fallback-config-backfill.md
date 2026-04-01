---
title: "Backfill broken objects with fallback configuration"
description: |
  Use the last known good configuration automatically for any subset of configuration that is invalid in your k8s cluster
content_type: how_to

permalink: /kubernetes-ingress-controller/fallback-configuration/backfill/

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
  q: How do I automatically use the last known good configuration for a subset of my {{ site.kic_product_name }} configuration?
  a: Enable the `FallbackConfiguration` feature gate and the `CONTROLLER_USE_LAST_VALID_CONFIG_FOR_FALLBACK=true` environment variable for {{ site.kic_product_name }}

prereqs:
  kubernetes:
    gateway_api: true
    feature_gates: FallbackConfiguration=true
    dump_config: true
    env:
      use_last_valid_config_for_fallback: true
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
  - text: "Exclude broken configuration"
    url: /kubernetes-ingress-controller/fallback-configuration/exclude/
---

## Backfilling broken objects

Fallback Configuration supports backfilling broken objects with their last valid version. To demonstrate this, we'll use the same setup as in the default mode, but this time we'll test with the `CONTROLLER_USE_LAST_VALID_CONFIG_FOR_FALLBACK` environment variable set to `true`.

{% include k8s/content/fallback-configuration/scenario-setup.md %}

## Break the Route

As we've verified that both `HTTPRoute`s are operational, let's break `route-b` again by removing the `rate-limit-consumer` `KongPlugin` from the `KongConsumer`:

```bash
kubectl annotate -n kong kongconsumer bob konghq.com/plugins-
```

## Verify the broken route was backfilled

Backfilling the broken `HTTPRoute` with its last valid version should have restored the Route to its last valid working state. That means we should be able to access `route-b` as before the breaking change:

{% validation request-check %}
url: /route-b
status_code: 404
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

The results should look like this:

```text
{
  "message":"No API key found in request",
  "request_id":"4604f84de6ed0b1a9357e935da5cea2c"
}
```

### Inspecting diagnostic endpoints

Using diagnostic endpoints, we can now inspect the objects that were excluded and backfilled in the configuration:

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
  ],
  "backfilledObjects": [
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
      "group": "configuration.konghq.com",
      "kind": "KongConsumer",
      "version": "v1",
      "namespace": "default",
      "name": "bob",
      "id": "deecb7c5-a3f6-4b88-a875-0e1715baa7c3",
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
        "configuration.konghq.com/KongPlugin:default/rate-limit-consumer",
        "gateway.networking.k8s.io/HTTPRoute:default/route-b"
      ]
    }
  ]
}
```
{:.no-copy-code}

As `rate-limit-consumer` and `route-b` were reported back as broken by the {{site.base_gateway}}, they were excluded from the configuration. However, the Fallback Configuration mechanism backfilled them with their last valid version, restoring the Route to its working state. You may notice that also the `KongConsumer` was backfilled. This is because the `KongConsumer` was depending on the `rate-limit-consumer` plugin in the last valid state.

{:.info}
> **Note:** The Fallback Configuration mechanism will attempt to backfill all the broken objects along with their direct and indirect dependants. The dependencies are resolved based on the last valid Kubernetes objects' cache state.

## Modify the affected objects

As we're now relying on the last valid version of the broken objects and their dependants, we won't be able to effectively modify them until we fix the problems. Let's try and add another key for the `bob` `KongConsumer`.

Create a new `Secret` with a new key:

```bash
echo 'apiVersion: v1
kind: Secret
metadata:
  name: bob-key-auth-new
  namespace: kong
  labels:
    konghq.com/credential: key-auth
stringData:
  key: bob-new-password' | kubectl apply -f -
```

Associate the new `Secret` with the `KongConsumer`:

```bash
kubectl patch -n kong kongconsumer bob --type merge -p '{"credentials":["bob-key-auth", "bob-key-auth-new"]}'
```

The change won't be effective as the `HTTPRoute` and `KongPlugin` are still broken. We can verify this by trying to access the `route-b` with the new key:

{% validation request-check %}
url: /route-b
headers:
  - "apikey:bob-new-password"
status_code: 404
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

The results should look like this:

```text
{
  "message":"Unauthorized",
  "request_id":"4c706c7e4e06140e56453b22e169df0a"
}
```

## Modify the working route

On the other hand, we can still modify the working `HTTPRoute`:

```bash
kubectl patch -n kong httproute route-a --type merge -p '{"spec":{"rules":[{"matches":[{"path":{"type":"PathPrefix","value":"/route-a-modified"}}],"backendRefs":[{"name":"echo","port":1027}]}]}}'
```

Let's verify the updated `HTTPRoute`:

{% validation request-check %}
url: /route-a-modified
status_code: 404
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

The results should look like this:
```text
Welcome, you are connected to node orbstack.
Running on Pod echo-bf9d56995-r8c86.
In namespace default.
With IP address 192.168.194.8.
```
{:.no-copy-code}

## Fixing the broken route

To fix the broken `HTTPRoute`, we need to associate the `rate-limit-consumer` `KongPlugin` back with the `KongConsumer`:

```bash
kubectl annotate -n kong kongconsumer bob konghq.com/plugins=rate-limit-consumer
```

This should unblock the changes we've made to the `bob-key-auth` `Secret`. Let's verify this by accessing the `route-b`
with the new key:

{% validation request-check %}
url: /route-b
headers:
  - "apikey:bob-new-password"
status_code: 404
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

The results should look like this now:

```text
Welcome, you are connected to node orbstack.
Running on Pod echo-bf9d56995-r8c86.
In namespace default.
With IP address 192.168.194.8.
```
{:.no-copy-code}
