---
title: How to restart {{site.base_gateway}} on Kubernetes
short_title: Restart {{site.base_gateway}} on Kubernetes
permalink: /how-to/restart-kong-gateway-kubernetes/
description: Apply a kong.conf change to a Helm-deployed data plane by replacing pods instead of running kong reload.
content_type: how_to

products:
  - gateway

works_on:
  - on-prem

tags:
  - kubernetes
  - helm

tldr:
  q: How do I restart {{site.base_gateway}} when it runs on Kubernetes?
  a: |
    Run `kubectl rollout restart` on the Deployment, so the new configuration comes from the manifest and survives a reschedule.

faqs:
  - q: Do I need to restart {{site.base_gateway}} manually if I use {{site.operator_product_name}}?
    a: |
      No. When you change a `DataPlane` or `GatewayConfiguration` spec, [{{site.operator_product_name}}](/operator/) rolls the data plane pods out itself.

prereqs:
  skip_product: true
  inline:
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/cluster
      icon_url: /assets/icons/kubernetes.svg
    - title: Helm
      include_content: prereqs/helm
    - title: A {{site.base_gateway}} data plane
      include_content: prereqs/kubernetes/gateway-dbless
      icon_url: /assets/icons/kubernetes.svg

cleanup:
  inline:
    - title: Uninstall {{site.base_gateway}}
      icon_url: /assets/icons/kubernetes.svg
      content: |
        ```bash
        helm uninstall kong-dp -n kong
        kubectl delete namespace kong
        ```

related_resources:
  - text: How to restart {{site.base_gateway}} in a Docker container
    url: /how-to/restart-kong-gateway-container/
  - text: Restart {{site.base_gateway}} when a mounted certificate changes
    url: /how-to/rotate-kong-conf-certificates-with-reloader/
  - text: Manage kong.conf
    url: /gateway/manage-kong-conf/
  - text: Using SSL certificates in {{site.base_gateway}}
    url: /gateway/ssl-certificates/

automated_tests: false
---

`kong.conf` values are rendered into the NGINX configuration when a node boots, so {{site.base_gateway}} has to be restarted before it picks up a change to one of them. On Kubernetes, that means replacing the pods rather than reloading the process inside them.

{:.warning}
> Don't run `kong reload` in a pod. The command works, but the running container then no longer matches its manifest, and the change is lost the next time the pod is rescheduled, scaled, or upgraded.

## Change a kong.conf value

Set a `kong.conf` parameter so we have something to apply. This example raises the log level.

1. Create a `values-log-level.yaml` file that adds `log_level` to the `env` block:

   ```bash
   cat <<EOF > values-log-level.yaml
   env:
     # Added for this guide
     log_level: debug
   EOF
   ```

   Keep this in a separate file and layer it on top of `values-dp.yaml` rather than editing `values-dp.yaml` in place. Helm merges multiple `--values` files from left to right, so the data plane keeps the settings it was installed with.

1. Apply the change:

   ```bash
   helm upgrade kong-dp kong/kong -n kong --values ./values-dp.yaml --values ./values-log-level.yaml --wait
   ```

   Changing the pod template makes Helm replace the pods, so this alone applies the new value. The next section covers the case where the file a parameter points to changes but the pod template doesn't, which is what happens when a mounted Secret is rotated.

## Restart the data plane

1. Record the current pod names and ages so we can compare afterwards:

   ```bash
   kubectl get pods -n kong -l app.kubernetes.io/instance=kong-dp
   ```

1. Trigger a rolling restart of the Deployment:

   ```bash
   kubectl rollout restart deployment/kong-dp-kong -n kong
   ```

1. Wait for the rollout to finish:

   ```bash
   kubectl rollout status deployment/kong-dp-kong -n kong --timeout=300s
   ```

## Validate

1. Confirm that the pods were replaced:

   ```bash
   kubectl get pods -n kong -l app.kubernetes.io/instance=kong-dp
   ```

   The pod names and `AGE` values have changed, and `RESTARTS` is `0`, because the pods are new rather than restarted in place.

1. Confirm that the new configuration is in effect:

   ```bash
   export DP_POD=$(kubectl get pods -n kong -l app.kubernetes.io/instance=kong-dp --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}')
   kubectl exec -n kong $DP_POD -- printenv KONG_LOG_LEVEL
   ```

   The value should be `debug`.

1. Confirm that {{site.base_gateway}} is serving traffic again:

   ```bash
   kubectl port-forward -n kong $DP_POD 8000:8000 > /dev/null &
   sleep 3
   curl -i localhost:8000
   kill %1
   ```

   {{site.base_gateway}} returns `HTTP 404` with `no Route matched with those values`, because no Route matches `/`. This confirms the proxy is listening.

With more than one replica and correctly configured readiness probes, the rolling restart replaces pods one at a time and requests keep succeeding. With a single replica, as in this guide, expect a gap in service while the pod is replaced.

{:.info}
> To trigger this rollout automatically whenever a mounted ConfigMap or Secret changes, see [Restart {{site.base_gateway}} when a mounted certificate changes](/how-to/rotate-kong-conf-certificates-with-reloader/).
