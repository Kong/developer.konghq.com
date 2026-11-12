---
title: "Recover a DB-less deployment managed by {{site.kic_product_name_short}}"
description: "Recover Kong Ingress Controller and DB-less Kong Gateway deployments after a controller outage or Kubernetes cluster loss."
content_type: reference
layout: reference
breadcrumbs:
  - /kubernetes-ingress-controller/
products:
  - kic
  - gateway
works_on:
  - on-prem
tags:
  - kubernetes
  - backup
  - restore
  - failover
related_resources:
  - text: Kubernetes disaster recovery guides
    url: /gateway/disaster-recovery/kubernetes/
  - text: Prepare for disaster recovery
    url: /gateway/disaster-recovery/kubernetes/prepare/
  - text: Test disaster recovery
    url: /gateway/disaster-recovery/kubernetes/test/
  - text: KIC high availability
    url: /kubernetes-ingress-controller/kic-high-availability/
---

You can recover a [DB-less](/gateway/db-less-mode/) {{site.base_gateway}} and a standalone {{site.kic_product_name}} in a replacement Kubernetes cluster.
This walkthrough restores a Helm release and its Kubernetes routing resources, then tests the replacement before you move traffic.

The failure is the loss of the original cluster.
No running gateway or last known good configuration is available.
The recovery source is the files and secrets that you saved before the failure.

## Starting deployment

The {{site.kic_product_name_short}} recovery example uses the following deployment:

* The [{{site.kic_product_name_short}} Helm installation](/kubernetes-ingress-controller/install/) with release `kong`, chart `kong/ingress`, and namespace `kong`.
* An Ingress named `echo`, with the ingress class `kong`, which routes `echo.example.com/echo` to the `echo` Service on port `1027`.
* A TLS Secret named `echo-tls` for `echo.example.com`.
* A replacement cluster with a working LoadBalancer implementation and access to the required container registry.

Set `PRIMARY_CONTEXT` and `RECOVERY_CONTEXT` to the kubeconfig contexts of the original and replacement clusters.

If you use Gateway API instead of Ingress, save the GatewayClass, Gateway, HTTPRoutes, and any ReferenceGrants instead of the Ingress manifest.
For an embedded controller in {{site.operator_product_name}}, use the [{{site.operator_product_name}} walkthrough](/operator/dataplanes/disaster-recovery/).

## Save the recovery files before the failure

{% include k8s/disaster-recovery/save-helm-release.md dir="kic" release="kong" namespace="kong" chart="kong/ingress" values_file="values.yaml" version_var="KIC_CHART_VERSION" %}

Record the revision of your [deployment repository](/gateway/disaster-recovery/kubernetes/prepare/#manage-configuration-as-code) that you will restore.
If your routing resources aren't in a repository, [export them from the running cluster](#export-routing-resources-without-a-repository).

Complete the recovery set from your deployment repository and secret store:

{% table %}
columns:
  - title: File
    key: file
  - title: Contents
    key: contents
rows:
  - file: "`values.yaml` and `ingress-<version>.tgz`"
    contents: The saved Helm values and chart
  - file: "`application.yaml`"
    contents: The desired Deployment and Service manifests for the echo application
  - file: "`routing.yaml`"
    contents: The Ingress and any Kong resources that it references, including authentication policies
  - file: "`tls.crt` and `tls.key`"
    contents: "The certificate and private key for the `echo-tls` Secret"
  - file: "`ca.crt`"
    contents: The CA certificate that the test client uses to trust the listener
{% endtable %}

For a drill, start with the [echo application manifest](/manifests/kic/echo-service.yaml) and save it as `application.yaml`.
Pin its image to the digest that the original cluster uses.

Save the following Ingress as `routing.yaml`, and apply it in the original cluster before you take the baseline:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo
  namespace: kong
spec:
  ingressClassName: kong
  tls:
    - hosts:
        - echo.example.com
      secretName: echo-tls
  rules:
    - host: echo.example.com
      http:
        paths:
          - path: /echo
            pathType: Prefix
            backend:
              service:
                name: echo
                port:
                  number: 1027
```

Supply a certificate that's valid for `echo.example.com`.
For a drill, a private test CA is enough.
Create `echo-tls` in the original cluster with the same Secret creation command that you use during recovery, but with `PRIMARY_CONTEXT` instead of `RECOVERY_CONTEXT`.

If your installation uses them, also include other Secrets, custom plugin artifacts, and cluster-scoped resources such as KongLicense.

### Export routing resources without a repository

Use this fallback only if the routing resources aren't in source control.
The export captures the current state of the cluster, including changes that someone applied manually.

Export the Ingress and Kong resources from the original namespace.
Add every other kind that your deployment uses, such as `kongconsumers` or `kongupstreampolicies`:

```bash
kubectl --context "$PRIMARY_CONTEXT" -n kong get ingress,kongplugins \
  -o yaml > recovery/kic/routing.yaml
```

Export cluster-scoped resources such as KongClusterPlugin with a separate command, without `-n`.
Don't add `secrets` to the export, because it writes credentials and private keys into a plain file.
Restore Secrets from your secret store instead.

Use [`yq`](https://github.com/mikefarah/yq) to remove the fields that Kubernetes generated for the original objects:

```bash
yq -i '.items[] |= (del(.status) | del(.metadata.uid, .metadata.resourceVersion,
  .metadata.creationTimestamp, .metadata.generation, .metadata.managedFields,
  .metadata.finalizers, .metadata.ownerReferences,
  .metadata.annotations."kubectl.kubernetes.io/last-applied-configuration"))' \
  recovery/kic/routing.yaml
```

Review the file, then commit it to a repository so that the next recovery starts from source control.

### Record the baseline

Before the drill, send the request from [Test the recovered route](#test-the-recovered-route) to the original load balancer.
Record the HTTP status and the echo response.

## Restore the release and its resources

Make sure that the replacement context points to the intended cluster:

```bash
kubectl --context "$RECOVERY_CONTEXT" cluster-info
```

Create the namespace:

```bash
kubectl --context "$RECOVERY_CONTEXT" create namespace kong
```

Recreate the listener Secret from the saved certificate and key:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong create secret tls echo-tls \
  --cert=recovery/kic/tls.crt --key=recovery/kic/tls.key
```

Restore any other Secrets that your values or routing configuration reference before you restore the resources that depend on them.
For Gateway API installations, install the saved Gateway API CRDs first.
The CRDs are separate from the routing objects.

Install the saved chart with the saved values:

```bash
helm install kong "recovery/kic/ingress-${KIC_CHART_VERSION}.tgz" \
  --kube-context "$RECOVERY_CONTEXT" -n kong \
  -f recovery/kic/values.yaml
```

The `helm install` command creates a new installation in the replacement cluster.
Keep the release name and namespace so that the Service names and controller settings that the chart generates stay the same.

Wait for the controller before you apply its routing resources:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong rollout status \
  deployment/kong-controller --timeout=300s
```

Don't wait for the DB-less gateway to become ready before you restore its configuration.
The gateway can need that configuration to pass its readiness check.

Restore the application:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong apply \
  -f recovery/kic/application.yaml
```

Restore the routes and their Kong configuration resources:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong apply \
  -f recovery/kic/routing.yaml
```

Wait for the sample backend:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong rollout status \
  deployment/echo --timeout=300s
```

## Test the recovered route

Read the new proxy address:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong get service kong-gateway-proxy
```

Set `RECOVERY_ADDRESS` to its external IP or hostname.
The address can be different from the original address.

Send a request directly to the new address, and keep the hostname of the application for HTTP and TLS:

```bash
curl --fail-with-body --cacert recovery/kic/ca.crt \
  --connect-to "echo.example.com:443:${RECOVERY_ADDRESS}:443" \
  https://echo.example.com/echo
```

Expect HTTP `200` and an echo response that identifies a pod in the replacement cluster.
If the request fails, check the response:

* `404` from the gateway: The route is missing or doesn't match.
* `503`: Check the backend Service and its endpoints.
* Certificate error: Check the restored Secret, the hostname, and the CA.

If the application uses authentication, repeat the authorized and unauthorized requests that you recorded.
A successful public echo request doesn't test authentication recovery.

To check that configuration updates still work, do the following:

1. Add a second path, `/echo-recovered`, to the saved Ingress, and apply `routing.yaml` again.
1. Repeat the request with that path, and expect the same successful response.
1. Remove the temporary path from the file, and apply the file again.

## Move traffic and finish recovery

Update the DNS record or external load balancer that serves `echo.example.com` to use the replacement address.
For a DNS-managed endpoint, replace the old A or AAAA address, or the CNAME target, with the new load balancer address.

Repeat the request without `--connect-to` to test the normal client entry point.
Record traffic recovery only when this request succeeds through the updated endpoint.

For failback, restore the accepted files to the original environment, and validate its address with `--connect-to`.
Then change the client endpoint back.
Before you resume GitOps, save any configuration changes that you made during recovery in the deployment repository.

The restored routing state is the revision that you saved in `routing.yaml`.
Changes made after that revision are missing.
In the [drill record](/gateway/disaster-recovery/kubernetes/test/#record-the-results), record the following:

* The revision
* The identity of the restored certificate
* The time when both traffic and configuration updates worked
