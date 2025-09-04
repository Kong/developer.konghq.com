---
title: "Sticky sessions in {{ site.kic_product_name }}"

description: Sticky sessions ensure that repeat client requests are routed to the same backend pod, which is essential for maintaining user session state.

breadcrumbs:
  - /kubernetes-ingress-controller/
  
content_type: reference
layout: reference

products:
  - kic

works_on:
  - on-prem
  - konnect

min_version:
  kic: "3.5"

related_resources:
  - text: Configure sticky sessions with drain support
    url: /kubernetes-ingress-controller/sticky-sessions-with-drain-support/
---

Sticky sessions ensure that repeat client requests are routed to the same backend pod, which is essential for maintaining user session state. When combined with drain support, you can implement graceful pod termination during deployments or scaling events, allowing existing sessions to complete while preventing new traffic from being routed to pods that are shutting down.

Kong's sticky sessions feature uses browser-managed cookies to route repeat requests from the same client to the same backend target. When a client first connects, Kong sets a cookie in the response. On subsequent requests, if the cookie is present and valid, Kong routes the client to the same target.

Sticky sessions are useful for:
- Session persistence across multiple requests
- Applications that store session state locally
- Improving cache hit rates

## Drain support

Drain support is a feature that allows Kong to gracefully handle terminating pods. When a pod begins the termination process in Kubernetes:

1. The pod is marked for termination but continues running
2. The pod's status changes to `Terminating`
3. With drain support enabled, Kong:
   - Identifies these terminating pods
   - Adds them to the upstream with a weight of 0
   - Allows existing connections to complete
   - Prevents new connections from being routed to these pods

This ensures a smooth transition during deployments, scaling events, or node maintenance.

To enable drain support, you must start {{site.kic_product_name}} with the `--enable-drain-support` flag set to `true`. You can do this:
* In your deployment YAML:

  ```yaml
  containers:
  - name: ingress-controller
    image: kong/kubernetes-ingress-controller:3.5
    args:
    - /kong-ingress-controller
    - --enable-drain-support=true
  ```

* With an environment variable:

  ```yaml
  env:
  - name: CONTROLLER_ENABLE_DRAIN_SUPPORT
    value: "true"
  ```

* In your Helm chart configuration:

  ```yaml
  controller:
    ingressController:
      env:
        enable_drain_support: "true"
  ```

* During installation:

  ```bash
  helm install kong kong/ingress -n kong --create-namespace \
    --set controller.ingressController.env.enable_drain_support=true
  ```

With sticky sessions and drain support enabled:

1. When a client first connects to your application, Kong will:
   - Route the request to one of the available pods
   - Set a cookie in the response

2. For subsequent requests from the same client, Kong will:
   - Check for the cookie
   - Route the request to the same backend pod

3. During a deployment or pod termination:
   - Kubernetes marks the pod as `Terminating`
   - {{site.kic_product_name}} identifies terminating pods
   - These pods remain in the upstream with weight set to 0
   - Existing sessions can complete their work
   - New sessions are routed to healthy pods

Combining sticky sessions with drain support provides a powerful way to maintain session affinity while ensuring graceful handling of pod terminations.

## Configuration options

The following options are available to configure sticky sessions:
{% table %}
columns:
  - title: Option
    key: option
  - title: Description
    key: description
rows:
  - option: "`cookie`"
    description: Name of the cookie used for tracking.
  - option: "`cookiePath`"
    description: Path attribute of the cookie, `/` by default.
{% endtable %}


## Limitations

- Sticky sessions rely on cookies, which may not be supported in all client environments
- Drain support requires the `--enable-drain-support` flag to be explicitly enabled