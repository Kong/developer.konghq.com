---
title: MeshExternalService
description: Declare external resources that services in the mesh can consume, enabling TLS, routing, and hostname customization.

content_type: reference
layout: reference
products:
    - mesh
breadcrumbs:
  - /mesh/

related_resources:
  - text: Policy Hub
    url: /mesh/policies/
  - text: Mesh DNS
    url: /mesh/dns/
  - text: Resource sizing guidelines
    url: /mesh/resource-sizing-guidelines/
  - text: Version compatibility
    url: /mesh/version-compatibility/

min_version:
  mesh: '2.8'

faqs:
  - q: "What's the difference between `MeshPassthrough` and `MeshExternalService`?"
    a: "The main difference is that `MeshExternalService` assigns a custom domain and can be targeted by policies. `MeshPassthrough` doesn't alter the address of the original host and can't be targeted by policies."
---

The `MeshExternalService` resource allows services running inside the mesh to consume services that are not part of the mesh.
You can declare external resources instead of relying on a [`MeshPassthrough`](/mesh/policies/meshpassthrough/) policy or passthrough mode in the mesh configuration. 

{:.warning}
> Currently you can't configure granular [`MeshTrafficPermission`](/mesh/policies/meshtrafficpermission/) policies for `MeshExternalService` resources.
> You can only enable or disable the whole traffic to `MeshExternalService` from a mesh.
> For more information, see [Controlling MeshExternalService access from Mesh](#controlling-meshexternalservice-access-from-mesh).

## Configuration

The following sections describe the parameters you can configure in a `MeshExternalService` resource.

{:.info}
> To use a `MeshExternalService`, you must enable a [zone egress](/mesh/zone-egress/) and [mutual TLS](/mesh/policies/mutual-tls/).

### Match

The `match` parameters specify the rules for matching traffic that will be routed to external resources defined in [`endpoints`](#endpoints).
The only `type` supported is `HostnameGenerator` (this field is optional). This means that {{site.mesh_product_name}} will match traffic directed to a hostname created by the [`HostnameGenerator`](/mesh/hostnamegenerator/) resource.
The `port` field is optional, when omitted, all traffic is matched.
The protocols supported are: `tcp`, `grpc`, `http`, and `http2`.

```yaml
match:
  type: HostnameGenerator
  port: 4244
  protocol: tcp
```

### Endpoints

The `endpoints` parameters specify the destination of the matched traffic.
You can define IPs, DNS names, and unix domain sockets.

```yaml
endpoints:
  - address: 1.1.1.1
    port: 12345
  - address: example.com
    port: 80
  - address: unix:///tmp/example.sock
```

### TLS

The `tls` parameters describe the TLS and verification behavior.
TLS origination happens on the [sidecar](/mesh/data-plane-proxy/), so if your application is already using TLS you might want to use [MeshPassthrough](/mesh/policies/meshpassthrough).
You can define TLS version requirements, allow renegotiation, verification of the SNI, the SAN, the custom CA and the client certificate and key for server verification.
To disable parts of the verification you can set a `mode`: `SkipSAN`, `SkipCA`, `SkipAll`, or `Secured` (default).

```yaml
tls:
  version:
    min: TLS12
    max: TLS13
  allowRenegotiation: false
  verification:
    mode: SkipCA
    serverName: "example.com"
    subjectAltNames:
      - type: Exact
        value: example.com
      - type: Prefix
        value: "spiffe://example.local/ns/local"
    caCert:
      inline: dGVzdA==
    clientCert:
      secret: "123"
    clientKey:
      secret: "456"
```

When TLS is enabled but `caCert` is not set, the sidecar uses the [auto-detected OS-specific CA](https://github.com/kumahq/kuma/blob/aba6518fca65bc7ab52e5328eb686a51a6f98a53/app/kuma-dp/pkg/dataplane/certificate/cert.go#L12).
You can override the default CA by setting the path in the environment variable `KUMA_DATAPLANE_RUNTIME_DYNAMIC_SYSTEM_CA_PATH` for the sidecar.

### DNS setup

{{site.mesh_product_name}} [automatically creates a `HostnameGenerator`](/mesh/hostnamegenerator/#local-meshexternalservice) resource with a `meshExternalService` selector for each `MeshExternalService` resource created.

Once it's created:
- {{site.mesh_product_name}} generates a hostname based on the specified template, or multiple hostnames if there are multiple `HostnameGenerators` matching.
- A VIP is allocated from the `242.0.0.0/8` range. This can be changed by `KUMA_IPAM_MESH_EXTERNAL_SERVICE_CIDR` environment variable.
- An Envoy cluster is created and uses endpoints defined in `spec.endpoints` as the [cluster endpoints](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/endpoint/v3/endpoint_components.proto).

{:.danger}
> Do **not** hijack original addresses.
> If you need to transparently pass traffic through the Mesh without modifying it, use [`MeshPassthrough`](/mesh/policies/meshpassthrough/).

For more information about accessing entire subdomains, see [Wildcard DNS matching in `MeshPassthrough`](/mesh/policies/meshpassthrough/#wildcard-dns-matching).

### Universal mode without transparent proxy

`MeshExternalService` works in Universal mode without transparent proxy, but you need to manually define an outbound that targets the correct `MeshExternalService` in the [`Dataplane` configuration](/mesh/data-plane-proxy/#dataplane-entity):

```yaml
networking:
  outbound:
    - port: 8080
      backendRef:
        kind: MeshExternalService
        name: mes-http
```

### Controlling MeshExternalService access from Mesh 

Currently, you can't configure a [`MeshTrafficPermission`](/mesh/policies/meshtrafficpermission) policy for a `MeshExternalService` resource. However, you can configure access to all external services on the mesh level. For example, you can disable 
outgoing traffic to all `MeshExternalService` resources:

{% navtabs "Environments" %}
{% navtab "Kubernetes" %}
```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  routing:
    defaultForbidMeshExternalServiceAccess: true
```
{% endnavtab %}
{% navtab "Universal" %}
```yaml
type: Mesh
name: default
routing:
  defaultForbidMeshExternalServiceAccess: true
```
{% endnavtab %}
{% endnavtabs %}

## Using MeshExternalService

In the following sections:
* TCP examples use the https://tcpbin.com/ TCP echo service.
* HTTP examples use the https://httpbin.konghq.com/ service for inspecting and debugging HTTP requests.
* gRPC examples use the https://grpcbin.test.k6.io/ gRPC Request & Response Service. You can use [grpcurl](https://github.com/fullstorydev/grpcurl) as a client, which is available in the [netshoot](https://github.com/nicolaka/netshoot) debug image.

These examples use a [single-zone deployment](/mesh/single-zone/) and the following `HostnameGenerator`:

{% policy_yaml %}
{% raw %}
```yaml
type: HostnameGenerator
name: example
mesh: default
spec:
  selector:
    meshExternalService:
      matchLabels:
        kuma.io/origin: zone # only consider local MeshExternalServices
  template: '{{ .DisplayName }}.svc.meshext.local'
```
{% endraw %}
{% endpolicy_yaml %}

In a [multi-zone deployment](/mesh/mesh-multizone-service-deployment/), when applying resources on the global control plane, you need to:
* Have a second `HostnameGenerator` with `matchLabels: kuma.io/origin: global` for resources applied on the global control plane.
* Adjust the URLs accordingly to match the template.

### TCP

This is a simple example of accessing `tcpbin.com` service without TLS that echoes back bytes sent to it:

{% policy_yaml %}
```yaml
type: MeshExternalService
name: mes-tcp
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 4242
    protocol: tcp
  endpoints:
    - address: tcpbin.com
      port: 4242
```
{% endpolicy_yaml %}

Running the following command should print `echo this` in the terminal:

```bash
echo 'echo this' | nc -q 3 mes-tcp.svc.meshext.local 4242
```

### TCP with TLS

This example builds up on the previous example adding TLS verification with default system CA.
Notice that we're using a TLS port `4243`.

{% policy_yaml %}
```yaml
type: MeshExternalService
name: mes-tcp-tls
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 4243
    protocol: tcp
  endpoints:
    - address: tcpbin.com
      port: 4243
  tls:
    enabled: true
    verification:
      serverName: tcpbin.com
```
{% endpolicy_yaml %}

Running the following command should print `echo this` in the terminal:

```bash
echo 'echo this' | nc -q 3 mes-tcp-tls.svc.meshext.local 4243
```

### TCP with mTLS

This example builds up on the previous example adding a client cert and key.
Notice that we're using an mTLS port `4244`.

{:.warning}
> In a real-world scenario, you should use a secret and refer to it using its name instead of using `inline`.

{% policy_yaml %}
```yaml
type: MeshExternalService
name: mes-tcp-mtls
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 4244
    protocol: tcp
  endpoints:
    - address: tcpbin.com
      port: 4244
  tls:
    enabled: true
    verification:
      serverName: tcpbin.com
      clientCert:
        inline: $CERT_CONTENT
      clientKey:
        inline: $KEY_CONTENT
```
{% endpolicy_yaml %}

Running the following command should print `echo this` in the terminal:

```bash
echo 'echo this' | nc -q 3 mes-tcp-mtls.svc.meshext.local 4244
```

### HTTP

This is a simple example using plaintext HTTP:

{% policy_yaml %}
```yaml
type: MeshExternalService
name: mes-http
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 80
    protocol: http
  endpoints:
    - address: httpbin.konghq.com
      port: 80
```
{% endpolicy_yaml %}

Running the following command should print `httpbin.konghq.com HTML` in the terminal:

```bash
curl -s http://mes-http.svc.meshext.local
```

### HTTPS

This example builds up on the previous example adding TLS verification with default system CA:

{% policy_yaml %}
```yaml
type: MeshExternalService
name: mes-https
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 80
    protocol: http
  endpoints:
    - address: httpbin.konghq.com
      port: 443
  tls:
    enabled: true
    verification:
      serverName: httpbin.konghq.com
```
{% endpolicy_yaml %}

Running the following command should print `httpbin.konghq.com HTML` in the terminal:

```bash
curl http://mes-https.svc.meshext.local
```

### gRPC

This is a simple example using plaintext gRPC:

{% policy_yaml %}
```yaml
type: MeshExternalService
name: mes-grpc
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 9000
    protocol: grpc
  endpoints:
    - address: grpcbin.test.k6.io
      port: 9000
```
{% endpolicy_yaml %}

Running the following command should print `grpcbin.test.k6.io` available methods:

```bash
grpcurl -plaintext -v mes-grpc.svc.meshext.local:9000 list
```

### gRPCS

This example builds up on the previous example adding TLS verification with default system CA.
Notice that we're using a different port `9001`.

{% policy_yaml %}
```yaml
type: MeshExternalService
name: mes-grpcs
mesh: default
spec:
  match:
    type: HostnameGenerator
    port: 9001
    protocol: grpc
  endpoints:
    - address: grpcbin.test.k6.io
      port: 9001
  tls:
    enabled: true
    verification:
      serverName: grpcbin.test.k6.io
```
{% endpolicy_yaml %}

Running the following command should print `grpcbin.test.k6.io` available methods:

```bash
grpcurl -plaintext -v mes-grpcs.svc.meshext.local:9001 list # this is using plaintext because Envoy is doing TLS origination
```

## All policy configuration settings

{% json_schema MeshExternalServices %}
