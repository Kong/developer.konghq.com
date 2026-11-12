---
title: "Disaster recovery for DB-less deployments managed by {{site.kic_product_name_short}}"
description: "Learn what to save to recover a DB-less {{site.base_gateway}} managed by {{site.kic_product_name}} after a Kubernetes cluster loss, the order to restore it in, and how to adapt the recovery to your deployment."
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

A [DB-less](/gateway/db-less-mode/) {{site.base_gateway}} managed by {{site.kic_product_name}} doesn't have a database.
{{site.kic_product_name_short}} builds the gateway configuration from Kubernetes resources, such as Ingresses, HTTPRoutes, and KongPlugins.
When you lose the cluster, you lose those resources, the Helm release, and the Secrets.
No running gateway or last known good configuration is available, so you rebuild the deployment from files that you saved outside the cluster.

{:.success}
> To run the full procedure end to end in a local cluster, see [Recover a {{site.kic_product_name_short}} deployment after a cluster loss](/kubernetes-ingress-controller/recover-from-cluster-loss/).

## What to save

Save the following items while the original deployment works.
We recommend that you keep the manifests in a Git repository that you deploy through CD or GitOps, because recovery is then a normal deployment of a known revision.
For more information, see [Manage configuration as code](/gateway/disaster-recovery/kubernetes/prepare/#manage-configuration-as-code).

{% table %}
columns:
  - title: Item
    key: item
  - title: Why you need it
    key: why
rows:
  - item: Helm values from `helm get values --all`, and the chart archive from `helm pull`
    why: Lets you install the same chart version with the same settings. Pulling the chart from the repository during an incident can install a newer version.
  - item: Routing resources
    why: "Ingresses, or the GatewayClass, Gateway, HTTPRoutes, and ReferenceGrants for Gateway API, plus the Kong resources that they reference, such as KongPlugins and KongConsumers."
  - item: Cluster-scoped Kong resources
    why: Resources such as KongClusterPlugin and KongLicense aren't in any namespace, so a namespace export misses them.
  - item: Gateway API CRDs
    why: For Gateway API installations, the CRD bundle at the version that you run. The CRDs are separate from the routing objects.
  - item: Secrets
    why: "TLS certificates and keys, the license, and credentials. Restore them from your secret store, not from a plaintext export."
  - item: Application manifests
    why: The Deployments and Services that the routes send traffic to.
  - item: Custom plugin artifacts
    why: The code or images of any custom plugins that the gateway loads.
{% endtable %}

## Restore order

In the replacement cluster, restore the deployment in the following order:

1. Restore the Gateway API CRDs, if you use Gateway API.
1. Restore the Secrets that the Helm values and the routing resources reference.
1. Install the saved chart with the saved values.
   Keep the release name and namespace, so that the Service names and controller settings that the chart generates stay the same.
1. Wait for the controller Deployment to become available.
1. Restore the application and the routing resources.

Don't wait for the DB-less gateway to become ready before you restore the routing resources.
The gateway can need that configuration to pass its readiness check.
For the same reason, don't use `helm install --wait` for the restore.

## Export routing resources without a repository

Use this fallback only if the routing resources aren't in source control.
The export captures the current state of the cluster, including changes that someone applied manually.

Run the export against the original cluster.
Export the Ingress and Kong resources from the original namespace.
Add every other kind that your deployment uses, such as `kongconsumers` or `kongupstreampolicies`:

```bash
kubectl -n kong get ingress,kongplugins \
  -o yaml > recovery/routing.yaml
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
  recovery/routing.yaml
```

Review the file, then commit it to a repository so that the next recovery starts from source control.

## Troubleshoot the recovered deployment

If a request through the replacement proxy fails, check the response:

{% table %}
columns:
  - title: Response
    key: response
  - title: Cause and fix
    key: fix
rows:
  - response: "`404` from the gateway"
    fix: The route is missing or doesn't match. Make sure that you applied the routing resources and that the request uses the right hostname and path.
  - response: "`503`"
    fix: The gateway can't reach the backend. Check the backend Service and its endpoints.
  - response: Certificate error
    fix: Check the restored TLS Secret, the hostname in the request, and the CA that the client trusts.
{% endtable %}

A successful request to a public route doesn't test authentication recovery.
If your routes use authentication, repeat the authorized and unauthorized requests that you recorded before the failure.

## Move traffic and fail back

The replacement proxy gets a new load balancer address.
Update the DNS record or external load balancer that serves your hostname to use it.
For a DNS-managed endpoint, replace the old A or AAAA address, or the CNAME target, with the new load balancer address.
Record traffic recovery only when a request through the normal client endpoint succeeds.

For failback, restore the accepted files to the original environment, and test its address directly.
Then change the client endpoint back.
Before you resume GitOps, save any configuration changes that you made during recovery in the deployment repository.

The restored routing state is the revision that you saved.
Changes made after that revision are missing.
