---
title: Deploy data planes on a dual-stack cluster
description: "Run {{ site.operator_product_name }} data planes on a dual-stack Kubernetes cluster and send traffic to them over both IPv4 and IPv6."
content_type: how_to

permalink: /operator/dataplanes/how-to/dual-stack/
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

tech_preview: true

min_version:
  operator: '2.4'

related_resources:
  - text: Deploy data planes on an IPv6-only cluster
    url: /operator/dataplanes/how-to/ipv6/
  - text: Kubernetes IPv4/IPv6 dual-stack
    url: https://kubernetes.io/docs/concepts/services-networking/dual-stack/

tldr:
  q: How do I run a data plane that accepts IPv4 and IPv6 traffic on a dual-stack Kubernetes cluster?
  a: Install {{ site.operator_product_name }} with the `--ip-family=dual` argument, then create a Gateway. Set `ipFamilies` and `ipFamilyPolicy` on the ingress Service in the `GatewayConfiguration` to control which IP families the ingress Service uses.

prereqs:
  show_works_on: true
  skip_product: true
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: Dual-stack Kubernetes cluster
      content: |
        This guide requires a Kubernetes cluster with [IPv4/IPv6 dual-stack networking](https://kubernetes.io/docs/concepts/services-networking/dual-stack/) configured, and `kubectl` configured to point at it.

        If you don't have one, create a local dual-stack cluster with [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation):

        1. Create a kind configuration file that sets the cluster's IP family to `dual`:

           ```bash
           cat <<EOF > kind-dual-stack.yaml
           kind: Cluster
           apiVersion: kind.x-k8s.io/v1alpha4
           networking:
             ipFamily: dual
           EOF
           ```

        1. Create the cluster from the configuration file:

           ```bash
           kind create cluster --name kong-dual-stack --config kind-dual-stack.yaml
           ```

           kind sets the current `kubectl` context to the new cluster.
      icon_url: /assets/icons/kubernetes.svg

faqs:
  - q: What IP family policy does the ingress Service use when `ipFamilies` and `ipFamilyPolicy` aren't set on a dual-stack cluster?
    a: |
      When `--ip-family` is set to `dual` and the `GatewayConfiguration` doesn't set `ipFamilies` or `ipFamilyPolicy`, {{ site.operator_product_name }} creates the ingress Service with the `PreferDualStack` policy.
      The data plane is exposed over both IPv4 and IPv6.
  - q: How do I expose a data plane over a single IP family on a dual-stack cluster?
    a: |
      To expose a data plane over a single IP family on a dual-stack cluster, set `ipFamilies` on the ingress Service in the `GatewayConfiguration` to one family, for example `[IPv6]`.
      The ingress Service then stays single-stack.
  - q: Why does the ingress Service use `PreferDualStack` when `ipFamilies` lists both families?
    a: |
      The Kubernetes API server requires a dual-stack policy when a Service lists two IP families.
      When `ipFamilies` names both IPv4 and IPv6 and `ipFamilyPolicy` isn't set, {{ site.operator_product_name }} sets the ingress Service's policy to `PreferDualStack`.
  - q: What happens if the cluster doesn't support the requested IP families?
    a: |
      The cluster must support the IP families and policy set on the ingress Service.
      For example, setting `ipFamilies: [IPv6]` on a cluster without IPv6 networking fails.
  - q: Can I set `ipFamilies` and `ipFamilyPolicy` on a `DataPlane` resource?
    a: |
      Yes. The `DataPlane` resource accepts the same `ipFamilies` and `ipFamilyPolicy` fields under `spec.network.services.ingress`.
  - q: How do I expose a data plane outside the cluster over IPv4 and IPv6?
    a: |
      To expose a data plane outside the cluster over IPv4 and IPv6, set the ingress Service `type` in the `GatewayConfiguration` to `LoadBalancer`:

      ```yaml
      spec:
        dataPlaneOptions:
          network:
            services:
              ingress:
                type: LoadBalancer
      ```

      The Gateway is programmed only after the cluster assigns an external address to the load balancer.
      Local clusters such as kind don't assign load balancer addresses by default.
  - q: How do I expose a data plane over IPv4 and IPv6 on AWS EKS?
    a: |
      On AWS EKS, the in-tree cloud provider only provisions IPv4-only Network Load Balancers.
      To expose a data plane externally over both IPv4 and IPv6 on EKS, install the [AWS Load Balancer Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html).
      Then, set the ingress Service type to `LoadBalancer` and add the following annotations to the ingress Service in your `GatewayConfiguration` so the AWS Load Balancer Controller provisions a dual-stack Network Load Balancer:

      ```yaml
      spec:
        dataPlaneOptions:
          network:
            services:
              ingress:
                type: LoadBalancer
                annotations:
                  service.beta.kubernetes.io/aws-load-balancer-type: external
                  service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
                  service.beta.kubernetes.io/aws-load-balancer-ip-address-type: dualstack
                  service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
      ```

---

{% include /k8s/kong-namespace.md %}

## Install {{ site.operator_product_name }}

Add the Kong Helm charts and update them:

```bash
helm repo add kong https://charts.konghq.com
helm repo update
```

Install {{ site.operator_product_name }} with the `--ip-family=dual` argument.
With this argument, {{ site.operator_product_name }} can create ingress Services with both IPv4 and IPv6 addresses.
Helm passes the argument to {{ site.operator_product_name }} through the chart's `args` value:

{% konnect %}
content: |
  ```bash
  helm upgrade --install kong-operator kong/kong-operator -n kong-system \
    --create-namespace \
    --wait \
    --set image.tag={{ site.data.operator_latest.release }} \
    --set env.ENABLE_CONTROLLER_KONNECT=true \
    --set 'args[0]=--ip-family=dual'
  ```
{% endkonnect %}

{% on_prem %}
content: |
  ```bash
  helm upgrade --install kong-operator kong/kong-operator -n kong-system \
    --create-namespace \
    --wait \
    --set image.tag={{ site.data.operator_latest.release }} \
    --set 'args[0]=--ip-family=dual'
  ```
{% endon_prem %}

{% include operator/kong-license.md %}

{% include operator/konnect-auth.md %}

## Create a Gateway

Create a `GatewayConfiguration`, a `GatewayClass`, and a `Gateway`:

{% konnect %}
content: |
  ```bash
  echo '
  apiVersion: gateway-operator.konghq.com/v2beta1
  kind: GatewayConfiguration
  metadata:
    name: dual-stack
    namespace: kong
  spec:
    konnect:
      authRef:
        name: konnect-api-auth
    dataPlaneOptions:
      deployment:
        podTemplateSpec:
          spec:
            containers:
              - image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
                name: proxy
      network:
        services:
          ingress:
            type: ClusterIP
            ipFamilies:
              - IPv4
              - IPv6
            ipFamilyPolicy: PreferDualStack
  ---
  apiVersion: gateway.networking.k8s.io/v1
  kind: GatewayClass
  metadata:
    name: dual-stack
  spec:
    controllerName: konghq.com/gateway-operator
    parametersRef:
      group: gateway-operator.konghq.com
      kind: GatewayConfiguration
      name: dual-stack
      namespace: kong
  ---
  apiVersion: gateway.networking.k8s.io/v1
  kind: Gateway
  metadata:
    name: kong
    namespace: kong
    annotations:
      gateway-operator.konghq.com/static-naming: "true"
  spec:
    gatewayClassName: dual-stack
    listeners:
      - name: http
        port: 80
        protocol: HTTP' | kubectl apply -f -
  ```
{% endkonnect %}

{% on_prem %}
content: |
  ```bash
  echo '
  apiVersion: gateway-operator.konghq.com/v2beta1
  kind: GatewayConfiguration
  metadata:
    name: dual-stack
    namespace: kong
  spec:
    dataPlaneOptions:
      deployment:
        podTemplateSpec:
          spec:
            containers:
              - image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
                name: proxy
      network:
        services:
          ingress:
            type: ClusterIP
            ipFamilies:
              - IPv4
              - IPv6
            ipFamilyPolicy: PreferDualStack
  ---
  apiVersion: gateway.networking.k8s.io/v1
  kind: GatewayClass
  metadata:
    name: dual-stack
  spec:
    controllerName: konghq.com/gateway-operator
    parametersRef:
      group: gateway-operator.konghq.com
      kind: GatewayConfiguration
      name: dual-stack
      namespace: kong
  ---
  apiVersion: gateway.networking.k8s.io/v1
  kind: Gateway
  metadata:
    name: kong
    namespace: kong
  spec:
    gatewayClassName: dual-stack
    listeners:
      - name: http
        port: 80
        protocol: HTTP' | kubectl apply -f -
  ```
{% endon_prem %}

The `GatewayConfiguration` sets `ipFamilies` to IPv4 and IPv6 with the `PreferDualStack` policy, so the data plane's ingress Service gets an IPv4 address and an IPv6 address, in that order.
It also sets the ingress Service type to `ClusterIP`, so the Gateway is programmed without waiting for a load balancer address.

Wait for the Gateway to be programmed:

```bash
kubectl wait --for=condition=programmed gateway/kong -n kong --timeout=300s
```

## Validate

Export the name of the data plane's ingress Service:

```bash
export INGRESS_SERVICE=$(kubectl get svc -n kong \
  -l gateway-operator.konghq.com/dataplane-service-type=ingress \
  -o jsonpath='{.items[0].metadata.name}')
```

Check the IP families of the ingress Service:

```bash
kubectl get svc $INGRESS_SERVICE -n kong \
  -o jsonpath='{.spec.ipFamilies}{"\t"}{.spec.ipFamilyPolicy}{"\n"}'
```

The ingress Service is a dual-stack Service:

```
["IPv4","IPv6"]	PreferDualStack
```
{:.no-copy-code}

Export the ingress Service's IPv4 and IPv6 cluster IPs:

```bash
export PROXY_IPV4=$(kubectl get svc $INGRESS_SERVICE -n kong -o jsonpath='{.spec.clusterIPs[0]}')
export PROXY_IPV6=$(kubectl get svc $INGRESS_SERVICE -n kong -o jsonpath='{.spec.clusterIPs[1]}')
```

Send a request to the proxy over IPv4 from a temporary Pod in the cluster:

```bash
kubectl run curl -n kong --rm -it --restart=Never --image=curlimages/curl -- \
  curl -s -w '\nremote_ip: %{remote_ip}\n' "http://$PROXY_IPV4"
```

The output includes the response from {{ site.base_gateway }} and the address that curl connected to:

```
{
  "message":"no Route matched with those values",
  "request_id":"b2c40d7291d8d0133a7b2f6c834d5464"
}
remote_ip: 10.96.249.178
```
{:.no-copy-code}

The `remote_ip` value is a dotted decimal address, which means the request used IPv4.

Send a request to the proxy over IPv6:

```bash
kubectl run curl -n kong --rm -it --restart=Never --image=curlimages/curl -- \
  curl -s -w '\nremote_ip: %{remote_ip}\n' "http://[$PROXY_IPV6]"
```

The output includes the response from {{ site.base_gateway }} and the address that curl connected to:

```
{
  "message":"no Route matched with those values",
  "request_id":"780b0503694882228829e12c85c46462"
}
remote_ip: fd00:10:96::64bb
```
{:.no-copy-code}

The `remote_ip` value is a colon-separated hexadecimal address, which means the request used IPv6.

{{ site.base_gateway }} returns a `no Route matched` error for both requests because the Gateway doesn't have any Routes yet.
These responses confirm that the data plane accepts connections over both IPv4 and IPv6.
