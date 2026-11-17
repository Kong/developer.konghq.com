---
title: Connect {{ site.operator_product_name }} to {{site.konnect_short_name}} over AWS PrivateLink
description: "Run {{ site.operator_product_name }} and its data planes against {{site.konnect_short_name}} without public internet egress, using an AWS PrivateLink VPC endpoint."
content_type: how_to

permalink: /operator/konnect/how-to/private-link/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect

products:
  - operator

works_on:
  - konnect

min_version:
  operator: '2.4'

tldr:
  q: How do I connect {{ site.operator_product_name }} to {{site.konnect_short_name}} over AWS PrivateLink?
  a: |
    Create a VPC endpoint for your {{site.konnect_short_name}} geo with Private DNS enabled, then set the `serverURL` of your `KonnectAPIAuthConfiguration` to the private host with the `/api` path, for example `https://us.svc.konghq.com/api`. {{ site.operator_product_name }} and the data planes it deploys then reach {{site.konnect_short_name}} through the private endpoints.

prereqs:
  inline:
    - title: AWS PrivateLink VPC endpoint
      position: before
      content: |
        Your Kubernetes cluster must run in an AWS VPC that has an interface VPC endpoint for your {{site.konnect_short_name}} geo:

        * Create the endpoint for the PrivateLink service of your geo and AWS region. [Regional PrivateLink service names](/gateway/aws-private-link/#regional-privatelink-service-names) lists the service names and DNS names.
        * Enable **Private DNS** on the endpoint, so that the geo's private host, for example `us.svc.konghq.com`, resolves to the endpoint inside the VPC.
        * Attach a security group that allows inbound TCP traffic on port `443` from your cluster nodes.

        For the AWS steps, see [AWS PrivateLink peering](/gateway/aws-private-link/).
      icon_url: /assets/icons/aws.svg

related_resources:
  - text: AWS PrivateLink peering
    url: /gateway/aws-private-link/
  - text: Status in {{site.konnect_short_name}}
    url: /operator/konnect/troubleshooting/status/
  - text: Reference {{site.konnect_short_name}} authentication across multiple namespaces
    url: /operator/konnect/how-to/auth-cross-namespace-reference/
  - text: Create a Dedicated Cloud Gateway network
    url: /operator/konnect/crd/cloud-gateways/network/

cleanup:
  inline:
    - title: Delete the resources created in this guide
      content: |
        Deleting the `Gateway` also deletes the `KonnectGatewayControlPlane` that {{ site.operator_product_name }}
        created for it, which removes the control plane from {{ site.konnect_short_name }}:

        ```bash
        kubectl delete -n kong --ignore-not-found gateway/kong gatewayconfiguration/gateway-configuration
        kubectl delete -n kong --ignore-not-found konnectgatewaycontrolplane --all
        kubectl delete --ignore-not-found gatewayclass/gateway-class
        kubectl delete -n kong --ignore-not-found konnectapiauthconfiguration/konnect-api-auth-private
        ```
        {: data-test-cleanup="block" }
      icon_url: /assets/icons/kubernetes.svg

faqs:
  - q: Do I need to distribute a CA certificate to connect {{ site.operator_product_name }} to {{site.konnect_short_name}} over AWS PrivateLink?
    a: |
      No. The private {{site.konnect_short_name}} host serves the same publicly trusted certificate as the public host, and {{ site.operator_product_name }} configures data planes to trust the system certificate bundle.
  - q: Which `serverURL` do I set for the global {{site.konnect_short_name}} API over AWS PrivateLink?
    a: |
      You don't set it.
      You always set the regional form in the `KonnectAPIAuthConfiguration`, for example `https://us.svc.konghq.com/api` instead of the public `https://us.api.konghq.com`.
      {{ site.operator_product_name }} derives the global form, for example `https://global.svc.konghq.com/api`, from it.
      {{ site.operator_product_name }} uses the global API for Dedicated Cloud Gateways.
  - q: How do I move an existing {{ site.operator_product_name }} installation from the public {{site.konnect_short_name}} hosts to AWS PrivateLink?
    a: |
      You can't change the `serverURL` of an existing `KonnectAPIAuthConfiguration`.
      Create a new `KonnectAPIAuthConfiguration` with the private `serverURL`, and point your resources at it.
  - q: Which egress rules do {{ site.operator_product_name }} and its data planes need with AWS PrivateLink?
    a: |
      With AWS PrivateLink, {{ site.operator_product_name }} and the data planes only need outbound HTTPS (TCP port `443`) to the VPC endpoint.
      They don't need any rule for the public {{site.konnect_short_name}} hosts.

      If a Kubernetes `NetworkPolicy` restricts egress from the {{ site.operator_product_name }} or data plane namespaces, allow TCP port `443` to the IP addresses of the VPC endpoint.
  - q: Do I need to change the `--konnect-server-url-domains` flag to use AWS PrivateLink?
    a: |
      No. The private {{site.konnect_short_name}} hosts are under `konghq.com`, which is one of the default allowed {{site.konnect_short_name}} domains.
  - q: What does {{ site.operator_product_name }} do when a component would connect to {{site.konnect_short_name}} over the public internet?
    a: |
      When a `KonnectAPIAuthConfiguration` uses a private `serverURL`, {{ site.operator_product_name }} doesn't start a component with a configuration that would send its traffic over the public internet.
      Instead, it holds the component and reports a condition that explains why.
      A held data plane keeps serving traffic, but {{ site.operator_product_name }} doesn't apply spec, image, or certificate changes to it until the condition clears.

      For example, a `KonnectExtension` reports `EndpointMismatch` when {{site.konnect_short_name}} doesn't return private endpoints for your geo yet.
      The condition clears on its own once {{site.konnect_short_name}} returns them, and you don't need to change anything in your cluster.

      For the full list of conditions, see [Status in {{site.konnect_short_name}}](/operator/konnect/troubleshooting/status/#private-endpoint-conditions).
  - q: Which {{ site.operator_product_name }} components can't connect to {{site.konnect_short_name}} over AWS PrivateLink?
    a: |
      The following components can't connect over AWS PrivateLink yet:

      * **{{ site.kic_product_name }} in {{site.konnect_short_name}}**: There's no private route for its API, so {{ site.operator_product_name }} holds a `KonnectExtension` for it with `InvalidEndpoint`.
      * **{{ site.ai_gateway }} data planes**: {{ site.operator_product_name }} holds the `AIGatewayDataPlane` with `EndpointMismatch`.
      * **{{ site.event_gateway }} data planes**: {{ site.event_gateway }} data planes can't use a `serverURL` with a path, so {{ site.operator_product_name }} holds the `KegDataPlane` with `EndpointMismatch`.
---

By default, {{ site.operator_product_name }} and the data planes it deploys reach {{site.konnect_short_name}} through its public hosts. With [AWS PrivateLink](/gateway/aws-private-link/), they can reach {{site.konnect_short_name}} through a VPC endpoint instead, without public internet egress.

The only setting that changes is the `serverURL` of the `KonnectAPIAuthConfiguration`. {{ site.operator_product_name }} uses it to call the {{site.konnect_short_name}} API, and {{site.konnect_short_name}} returns private control plane and telemetry endpoints for the data planes to connect to.

## Export the private server URL

Export the private {{site.konnect_short_name}} API URL for your geo.
The URL is the private host of your geo, followed by the `/api` path.
This example uses the US geo. For another geo, replace `us` with your geo:

```bash
export KONNECT_PRIVATE_SERVER_URL='https://us.svc.konghq.com/api'
```
{: data-test-step="block" }

## Create the KonnectAPIAuthConfiguration

Create the `kong` namespace and a `KonnectAPIAuthConfiguration` that uses the private server URL:

```bash
kubectl create namespace kong --dry-run=client -o yaml | kubectl apply -f -

echo '
kind: KonnectAPIAuthConfiguration
apiVersion: konnect.konghq.com/v1alpha1
metadata:
  name: konnect-api-auth-private
  namespace: kong
spec:
  type: token
  token: '"$KONNECT_TOKEN"'
  serverURL: '"$KONNECT_PRIVATE_SERVER_URL"'
' | kubectl apply -f -
```
{: data-test-step="block" }

Check that the authentication is valid and that the organization was resolved:

```bash
kubectl get konnectapiauthconfiguration konnect-api-auth-private -n kong \
  -o jsonpath='{.status.conditions[?(@.type=="APIAuthValid")].status} {.status.organizationID}{"\n"}'
```
{: data-test-step="block" }

The command prints `True` followed by your organization ID.

## Create the Gateway

Create a `GatewayConfiguration` that references the `KonnectAPIAuthConfiguration`, then a `GatewayClass` and a `Gateway`. The rest of the configuration is the same as for a deployment over the public hosts:

```bash
echo '
kind: GatewayConfiguration
apiVersion: gateway-operator.konghq.com/{{ site.operator_gatewayconfiguration_api_version }}
metadata:
  name: gateway-configuration
  namespace: kong
spec:
  konnect:
    authRef:
      name: konnect-api-auth-private
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
            - name: proxy
              image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
---
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: gateway-class
spec:
  controllerName: konghq.com/gateway-operator
  parametersRef:
    group: gateway-operator.konghq.com
    kind: GatewayConfiguration
    name: gateway-configuration
    namespace: kong
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong
  namespace: kong
spec:
  gatewayClassName: gateway-class
  listeners:
    - name: http
      port: 80
      protocol: HTTP
' | kubectl apply -f -
```
{: data-test-step="block" }

## Validate

1. Wait for the `KonnectGatewayControlPlane` that {{ site.operator_product_name }} created for the `Gateway` to be programmed:

   ```bash
   kubectl wait --for=condition=Programmed --all -n kong konnectgatewaycontrolplane --timeout=5m
   ```
   {: data-test-step="block" }

1. Check that {{site.konnect_short_name}} returned private endpoints for the control plane:

   ```bash
   kubectl get konnectgatewaycontrolplane -n kong \
     -o jsonpath='{range .items[*]}{.status.konnectEndpoints.controlPlane}{"\n"}{.status.konnectEndpoints.telemetry}{"\n"}{end}'
   ```
   {: data-test-step="block" }

   Both endpoints use the private host, for example:

   ```text
   https://us.svc.konghq.com/cp/PREFIX
   https://us.svc.konghq.com/tp/PREFIX
   ```
   {:.no-copy-code}

1. Check that the data plane is configured with the private endpoints:

   ```bash
   kubectl get deployment -n kong -o yaml \
     | grep -A1 -E 'KONG_CLUSTER_(CONTROL_PLANE|SERVER_NAME|TELEMETRY_ENDPOINT)$'
   ```
   {: data-test-step="block" }

   The values use the private host, for example:

   ```text
   - name: KONG_CLUSTER_CONTROL_PLANE
     value: us.svc.konghq.com/cp/PREFIX
   - name: KONG_CLUSTER_SERVER_NAME
     value: us.svc.konghq.com
   - name: KONG_CLUSTER_TELEMETRY_ENDPOINT
     value: us.svc.konghq.com:443/tp/PREFIX
   ```
   {:.no-copy-code}
