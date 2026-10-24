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

Recover a DB-less {{site.base_gateway}} and standalone {{site.kic_product_name}} in a replacement Kubernetes cluster. This walkthrough restores a Helm release and its Kubernetes routing resources, then tests the replacement before moving traffic.

The failure is loss of the original cluster. No running gateway or last known good configuration is available. The recovery source is the files and secrets you saved before the failure.

## Starting deployment

This example uses:

* The [KIC Helm installation](/kubernetes-ingress-controller/install/) with release `kong`, chart `kong/ingress`, and namespace `kong`.
* An Ingress named `echo`, using ingress class `kong`, which routes `echo.example.com/echo` to the `echo` Service on port `1027`.
* A TLS Secret named `echo-tls` for `echo.example.com`.
* A replacement cluster with a working LoadBalancer implementation and access to the required container registry.

Use two distinct kubeconfig contexts. Set `PRIMARY_CONTEXT` to the original cluster and `RECOVERY_CONTEXT` to the empty replacement. Every cluster command in this guide names its context.

If you use Gateway API instead of Ingress, preserve the GatewayClass, Gateway, HTTPRoutes, and any ReferenceGrants in place of the Ingress manifest. For an embedded Operator controller, use the [Operator walkthrough](/operator/dataplanes/disaster-recovery/).

## Save the recovery files before the failure

Create a protected working directory outside the cluster:

```bash
mkdir -p recovery/kic
```

Save the release's effective values:

```bash
helm get values kong -n kong --kube-context "$PRIMARY_CONTEXT" \
  --all -o yaml > recovery/kic/values.yaml
```

Read the installed chart version:

```bash
helm list -n kong --kube-context "$PRIMARY_CONTEXT"
```

Set `KIC_CHART_VERSION` to the version shown after `ingress-` in the `CHART` column. Download that exact chart from the configured Kong Helm repository:

```bash
helm pull kong/ingress --version "$KIC_CHART_VERSION" \
  --destination recovery/kic
```

The recommended source for the remaining files is a Git repository deployed through CD or GitOps; see [Manage configuration as code](/gateway/disaster-recovery/kubernetes/prepare/#manage-configuration-as-code). Record the revision you will restore. If your routing resources aren't in a repository, [export them from the running cluster](#export-routing-resources-without-a-repository).

Complete this recovery set using your deployment repository and secret store:

| File | Contents |
| --- | --- |
| `values.yaml` and `ingress-<version>.tgz` | The saved Helm values and chart |
| `application.yaml` | The desired Deployment and Service manifests for the echo application |
| `routing.yaml` | The Ingress and any referenced Kong resources, including authentication policies |
| `tls.crt` and `tls.key` | The certificate and private key for the `echo-tls` Secret |
| `ca.crt` | The CA certificate used by the test client to trust the listener |

For a drill, start with the [echo application manifest](/manifests/kic/echo-service.yaml) and save it as `application.yaml`. Pin its image to the digest used in the original cluster. Save this Ingress as `routing.yaml` and apply it in the original cluster before taking the baseline:

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

Supply a certificate valid for `echo.example.com`; a private test CA is sufficient for a drill. Create `echo-tls` in the original cluster using the same Secret creation command used during recovery, with `PRIMARY_CONTEXT` in place of `RECOVERY_CONTEXT`.

Keep the complete set in protected storage outside the failed cluster. Helm values and private keys can contain secrets. Include additional Secrets, custom plugin artifacts, and cluster-scoped resources such as KongLicense if your installation uses them.

### Export routing resources without a repository

Use this fallback only if the routing resources aren't in source control. It captures the cluster's current state, including changes that were applied by hand.

Export the Ingress and Kong resources from the original namespace. Add every other kind your deployment uses, such as `kongconsumers` or `kongupstreampolicies`:

```bash
kubectl --context "$PRIMARY_CONTEXT" -n kong get ingress,kongplugins \
  -o yaml > recovery/kic/routing.yaml
```

Export cluster-scoped resources such as KongClusterPlugin with a separate command without `-n`. Don't add `secrets` to the export, because it writes credentials and private keys into a plain file. Restore those from your secret store.

Remove the fields that Kubernetes generates for the original objects. With [`yq`](https://github.com/mikefarah/yq) installed, run:

```bash
yq -i '.items[] |= (del(.status) | del(.metadata.uid, .metadata.resourceVersion,
  .metadata.creationTimestamp, .metadata.generation, .metadata.managedFields,
  .metadata.finalizers, .metadata.ownerReferences,
  .metadata.annotations."kubectl.kubernetes.io/last-applied-configuration"))' \
  recovery/kic/routing.yaml
```

Review the file, then commit it to a repository so that the next recovery starts from source control.

### Record the baseline

Before the drill, perform the request in [Test the recovered route](#test-the-recovered-route) against the original load balancer. Record the HTTP status and echo response.

## Restore the release and its resources

Confirm that the replacement context is the intended cluster:

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

Restore other Secrets referenced by your values or routing configuration before their dependent resources. For Gateway API installations, install the saved Gateway API CRDs first; they are separate from the routing objects.

Install the saved chart with the saved values:

```bash
helm install kong "recovery/kic/ingress-${KIC_CHART_VERSION}.tgz" \
  --kube-context "$RECOVERY_CONTEXT" -n kong \
  -f recovery/kic/values.yaml
```

This is a new installation in the replacement cluster. Keep the release name and namespace so that chart-generated Service names and controller settings remain consistent. Wait for the controller before applying its routing resources:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong rollout status \
  deployment/kong-controller --timeout=300s
```

Do not wait for the DB-less gateway to become ready before restoring its configuration. It may need that configuration to pass its readiness check.

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

Set `RECOVERY_ADDRESS` to its external IP or hostname. It can differ from the original address. Test directly against it while retaining the application's hostname for HTTP and TLS:

```bash
curl --fail-with-body --cacert recovery/kic/ca.crt \
  --connect-to "echo.example.com:443:${RECOVERY_ADDRESS}:443" \
  https://echo.example.com/echo
```

Expect HTTP `200` and the echo application's response identifying a pod in the replacement cluster. A Gateway `404` means the route is missing or does not match. A `503` requires checking the backend Service and its endpoints. A certificate error requires checking the restored Secret, hostname, and CA.

If the application has authentication, repeat its recorded authorized and unauthorized requests. A successful public echo request does not test authentication recovery.

To test continuing configuration updates, add a second path, `/echo-recovered`, to the saved Ingress, apply `routing.yaml` again, and repeat the request with that path. Expect the same successful response. Remove the temporary path from the file and reapply it after testing.

## Move traffic and finish recovery

Update the DNS record or external load balancer that serves `echo.example.com` to use the replacement address. For a DNS-managed endpoint, replace the old A/AAAA address or CNAME target with the new load balancer address.

Repeat the request without `--connect-to` to test the normal client entry point. Record traffic recovery only when this request succeeds through the updated endpoint.

For failback, restore the accepted files to the original environment, validate its address with `--connect-to`, and then change the client endpoint back. Preserve any configuration changes made during recovery in the deployment repository before resuming GitOps.

The restored routing state is the revision saved in `routing.yaml`; later changes are absent. Record that revision, the restored certificate identity, and the time at which both traffic and configuration updates worked in the [drill record](/gateway/disaster-recovery/kubernetes/test/#record-the-results).
