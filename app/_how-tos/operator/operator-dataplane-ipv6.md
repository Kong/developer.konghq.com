---
title: Deploy DataPlanes on IPv6 or dual-stack clusters
description: "Run {{ site.operator_product_name }} DataPlanes on IPv6-only, IPv4-only, and dual-stack Kubernetes clusters."
content_type: how_to

permalink: /operator/dataplanes/how-to/ipv6/
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "How-To"

products:
  - operator

works_on:
  - on-prem
  - konnect

min_version:
  operator: '2.4'

related_resources:
  - text: Provision a Gateway
    url: /operator/get-started/gateway-api/deploy-gateway/

tldr:
  q: How do I run a DataPlane on an IPv6-only or dual-stack Kubernetes cluster?
  a: Set the operator's `--ip-family` flag, optionally control the ingress Service IP families with `ipFamilies` and `ipFamilyPolicy`, and on AWS use the AWS Load Balancer Controller with dual-stack annotations.

prereqs:
  skip_product: true
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: Kubernetes cluster
      include_content: prereqs/kubernetes/cluster
    - title: IPv6 networking
      content: |
        The cluster must have IPv6 networking configured. On AWS EKS, the VPC and subnets must have an IPv6 CIDR block.

---

{{ site.operator_product_name }} supports IPv4-only, IPv6-only, and dual-stack Kubernetes clusters. The operator decides which IP families the DataPlane's Kong proxy, admin, status, and stream listeners bind to. The IP families of the ingress Service that exposes the DataPlane are controlled separately.

IPv6-only support requires {{ site.operator_product_name }} 2.4 or later. Dual-stack support is available as tech preview.

## Set the operator's IP family

The operator determines the cluster's IP family with the `--ip-family` flag:

| Value | Behavior |
|-------|----------|
| `auto` | Default. Detects the cluster's IP family from the `default/kubernetes` Service at startup. If detection fails, the operator exits with an error |
| `ipv4` | The operator expects an IPv4 cluster |
| `ipv6` | The operator expects an IPv6 cluster |
| <span style="white-space: nowrap;">`dual` <a class="badge bg-semantic-yellow-secondary text-semantic-yellow-primary" href="{{ site.data.stages.tech_preview.url }}">{{ site.data.stages.tech_preview.text }}</a></span> | The operator expects a dual-stack cluster |

In most clusters the default `auto` detection works and no configuration is needed. If detection fails, set the flag explicitly with the Helm chart's `args` value:

```yaml
# values.yaml
args:
  - --ip-family=ipv6
```

```bash
helm upgrade --install kong-operator kong/kong-operator -n kong-system \
  --create-namespace \
  --set image.tag={{ site.data.operator_latest.release }} \
  -f values.yaml
```

## Control the ingress Service IP family

This section applies to dual-stack clusters only.

By default, when the operator's IP family is `dual`, the ingress Service is created with the `PreferDualStack` policy so that the DataPlane is exposed over both IPv4 and IPv6. You can override this with the `ipFamilies` and `ipFamilyPolicy` fields on the ingress Service of a `GatewayConfiguration`:

```yaml
spec:
  dataPlaneOptions:
    network:
      services:
        ingress:
          ipFamilies:
            - IPv4
            - IPv6
          ipFamilyPolicy: PreferDualStack
```

The fields behave like their [Kubernetes Service dual-stack](https://kubernetes.io/docs/concepts/services-networking/dual-stack/) counterparts:

- If neither field is set on a dual-stack cluster, the Service defaults to `PreferDualStack`
- If `ipFamilies` names a single family, the Service stays single-stack
- If `ipFamilies` names both families, the Service defaults to `PreferDualStack`, because the Kubernetes API server requires a dual-stack policy when two families are specified

The requested settings must be supported by the cluster. For example, `ipFamilies: [IPv6]` on a cluster without IPv6 networking fails.

The same fields are available on the `DataPlane` resource under `spec.network.services.ingress`.

## AWS EKS requirements

On AWS EKS, the in-tree cloud provider only provisions IPv4-only Network Load Balancers.

To expose a DataPlane externally on an IPv6-only or dual-stack EKS cluster, you must use the [AWS Load Balancer Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html).

Then annotate the ingress Service through the `GatewayConfiguration` so that the controller provisions a dual-stack load balancer:

```yaml
spec:
  dataPlaneOptions:
    network:
      services:
        ingress:
          annotations:
            service.beta.kubernetes.io/aws-load-balancer-type: external
            service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
            service.beta.kubernetes.io/aws-load-balancer-ip-address-type: dualstack
            service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
```

## Validate

Deploy a Gateway following the [Provision a Gateway](/operator/get-started/gateway-api/deploy-gateway/) guide.

If you're on AWS EKS, apply the [AWS EKS requirements](#aws-eks-requirements) sections to the `GatewayConfiguration`.

Wait for the Gateway to become programmed:

```bash
kubectl wait --for=condition=programmed gateway/kong -n kong --timeout=300s
```

Check the IP families of the ingress Service:

```bash
kubectl get svc -n kong -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.ipFamilies}{"\t"}{.spec.ipFamilyPolicy}{"\n"}{end}'
```
An IPv6-only Service reports:

```
{svc-name} ["IPv6"] SingleStack
```
{:.no-copy-code}

A dual-stack Service reports both families:

```
{svc-name} ["IPv4","IPv6"] PreferDualStack
```
{:.no-copy-code}

To test IPv6 connectivity from outside the cluster, resolve the load balancer's DNS name and connect to its `AAAA` record:

```bash
dig AAAA <load-balancer-dns-name>
```
