---
title: Configuring built-in listeners
description: 'Reference for configuring built-in listeners using MeshGateway, including listener setup, TLS termination, hostnames, and cross-mesh support.'

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

related_resources:
  - text: Add a builtin gateway
    url: /how-to/set-up-a-built-in-mesh-gateway/
  - text: Built-in gateways
    url: /mesh/built-in-gateway/
  - text: Configuring built-in routes
    url: /mesh/gateway-routes/

min_version:
  mesh: '2.6'
---

{% capture k8s_service_selector_suffix %}{% if_version gte:2.7.x inline:true %}_default_svc{% endif_version %}{% endcapture %}

For configuring built-in gateway listeners, use the `MeshGateway` resource.

{:.info}
> These are {{site.mesh_product_name}} policies so if you are running on multi-zone they need to be created on the Global CP.
> See the [dedicated section](/mesh/built-in-gateway/#multi-zone) for using builtin gateways on multi-zone.

The `MeshGateway` resource specifies what network ports the gateway should listen on and how network traffic should be accepted.
A builtin gateway Dataplane can have exactly one `MeshGateway` resource bound to it.
This binding uses standard, tag-based {{site.mesh_product_name}} matching semantics:

{% if_version gte:2.7.x lte:2.9.x %}

{:.warning}
> **Heads up!**
> In previous versions of {{site.mesh_product_name}}, setting the `kuma.io/service` tag directly within a `MeshGatewayInstance` resource was used to identify the service. However, this practice is deprecated and no longer recommended for security reasons since {{site.mesh_product_name}} version 2.7.0.
>
> We've automatically switched to generating the service name for you based on your `MeshGatewayInstance` resource name and namespace (format: `{name}_{namespace}_svc`).

{% endif_version %}

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGateway
mesh: default
metadata:
  name: edge-gateway
spec:
  selectors:
    - match:
        kuma.io/service: edge-gateway{{ k8s_service_selector_suffix }}
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: MeshGateway
mesh: default
name: edge-gateway
selectors:
  - match:
      kuma.io/service: edge-gateway
```

{% endnavtab %}
{% endnavtabs %}

A `MeshGateway` can have any number of listeners, where each listener represents an endpoint that can accept network traffic.
Note that the `MeshGateway` doesn't specify which IP addresses are listened on; the `Dataplane` resource specifies that.

To configure a listener, you need to specify at least the port number and network protocol.
Each listener may also have its own set of {{site.mesh_product_name}} tags so that {{site.mesh_product_name}} policy configuration can be targeted to specific listeners.

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGateway
mesh: default
metadata:
  name: edge-gateway
spec:
  selectors:
    - match:
        kuma.io/service: edge-gateway{{ k8s_service_selector_suffix }}
  conf:
    listeners:
      - port: 8080
        protocol: HTTP
        tags:
          port: http-8080
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: MeshGateway
mesh: default
name: edge-gateway
selectors:
  - match:
      kuma.io/service: edge-gateway
conf:
  listeners:
    - port: 8080
      protocol: HTTP
      tags:
        port: http-8080
```

{% endnavtab %}
{% endnavtabs %}

#### Hostname

An HTTP or HTTPS listener can also specify a `hostname`.

Note that listeners can share both `port` and `protocol` but differ on `hostname`.
This way routes can be attached to requests to specific _hostnames_ but share
the port/protocol with other routes attached to other hostnames.

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGateway
mesh: default
metadata:
  name: edge-gateway
spec:
  selectors:
    - match:
        kuma.io/service: edge-gateway{{ k8s_service_selector_suffix }}
  conf:
    listeners:
      - port: 8080
        protocol: HTTP
        hostname: foo.example.com
        tags:
          port: http-8080
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: MeshGateway
mesh: default
name: edge-gateway
selectors:
  - match:
      kuma.io/service: edge-gateway
conf:
  listeners:
    - port: 8080
      protocol: HTTP
      hostname: foo.example.com
      tags:
        port: http-8080
```

{% endnavtab %}
{% endnavtabs %}

In the above example, the gateway proxy listens for HTTP protocol connections on TCP port 8080 but restricts the `Host` header to `foo.example.com`.

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGateway
mesh: default
metadata:
  name: edge-gateway
spec:
  selectors:
    - match:
        kuma.io/service: edge-gateway{{ k8s_service_selector_suffix }}
  conf:
    listeners:
      - port: 8080
        protocol: HTTP
        hostname: foo.example.com
        tags:
          vhost: foo.example.com
      - port: 8080
        protocol: HTTP
        hostname: bar.example.com
        tags:
          vhost: bar.example.com
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: MeshGateway
mesh: default
name: edge-gateway
selectors:
  - match:
      kuma.io/service: edge-gateway
conf:
  listeners:
    - port: 8080
      protocol: HTTP
      hostname: foo.example.com
      tags:
        vhost: foo.example.com
    - port: 8080
      protocol: HTTP
      hostname: bar.example.com
      tags:
        vhost: bar.example.com
```

{% endnavtab %}
{% endnavtabs %}

Above shows a `MeshGateway` resource with two HTTP listeners on the same port.
In this example, the gateway proxy will be configured to listen on port 8080, and accept HTTP requests for both hostnames.

Note that because each listener entry has its own {{site.mesh_product_name}} tags, policy can still be targeted to a specific listener.
{{site.mesh_product_name}} generates a set of tags for each listener by combining the tags from the listener, the `MeshGateway` and the `Dataplane`.
{{site.mesh_product_name}} matches policies against this set of combined tags.

{% table %}
columns:
  - title: "`Dataplane` tags"
    key: dataplane_tags
  - title: Listener tags
    key: listener_tags
  - title: Final Tags
    key: final_tags
rows:
  - dataplane_tags: "kuma.io/service=edge-gateway{{ k8s_service_selector_suffix }}"
    listener_tags: "vhost=foo.example.com"
    final_tags: "kuma.io/service=edge-gateway{{ k8s_service_selector_suffix }},vhost=foo.example.com"
  - dataplane_tags: "kuma.io/service=edge-gateway{{ k8s_service_selector_suffix }}"
    listener_tags: "kuma.io/service=example,domain=example.com"
    final_tags: "kuma.io/service=example,domain=example.com"
  - dataplane_tags: "kuma.io/service=edge{{ k8s_service_selector_suffix }},location=us"
    listener_tags: "version=2"
    final_tags: "kuma.io/service=edge{{ k8s_service_selector_suffix }},location=us,version=2"
{% endtable %}

## TLS Termination

TLS sessions are terminated on a Gateway by specifying the "HTTPS" protocol, and providing a server certificate configuration.
Below, the gateway listens on port 8443 and terminates TLS sessions.

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGateway
mesh: default
metadata:
  name: edge-gateway
spec:
  selectors:
    - match:
        kuma.io/service: edge-gateway{{ k8s_service_selector_suffix }}
  conf:
    listeners:
      - port: 8443
        protocol: HTTPS
        hostname: foo.example.com
        tls:
          mode: TERMINATE
          certificates:
            - secret: foo-example-com-certificate
        tags:
          name: foo.example.com
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: MeshGateway
mesh: default
name: edge-gateway
selectors:
  - match:
      kuma.io/service: edge-gateway
conf:
  listeners:
    - port: 8443
      protocol: HTTPS
      hostname: foo.example.com
      tls:
        mode: TERMINATE
        certificates:
          - secret: foo-example-com-certificate
      tags:
        name: foo.example.com
```

{% endnavtab %}
{% endnavtabs %}

The server certificate is provided through a {{site.mesh_product_name}} datasource reference, in this case naming a secret that must contain both the server certificate and the corresponding private key.

### Server Certificate Secrets

A TLS server certificate secret is a collection of PEM objects in a {{site.mesh_product_name}} datasource (which may be a file, a {{site.mesh_product_name}} secret, or inline data).

There must be at least a private key and the corresponding TLS server certificate.
The CA certificate chain may also be present, but if it is, the server certificate must be the first certificate in the secret.

{{site.mesh_product_name}} gateway supports serving both RSA and ECDSA server certificates.
To enable this support, generate two server certificate secrets and provide them both to the listener TLS configuration.
The `kumactl` tool supports generating simple, self-signed TLS server certificates. The script below shows how to do this.

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: foo-example-com-certificate
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: default
data:
  value: "$(kumactl generate tls-certificate --type=server --hostname=foo.example.com --key-file=- --cert-file=- | base64 -w0)"
type: system.kuma.io/secret
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: Secret
mesh: default
name: foo-example-com-certificate
data: $(kumactl generate tls-certificate --type=server --hostname=foo.example.com --key-file=- --cert-file=- | base64 -w0)
```

{% endnavtab %}
{% endnavtabs %}

### Cross-mesh

The `Mesh` abstraction allows users
to encapsulate and isolate services
inside a kind of sub-mesh with its own CA.
With a cross-mesh `MeshGateway`,
you can expose the services of one `Mesh`
to other `Mesh`es by defining an API with `MeshHTTPRoute`s.
All traffic remains inside the {{site.mesh_product_name}} data plane protected by mTLS.

All meshes involved in cross-mesh communication must have mTLS enabled.
To enable cross-mesh functionality for a `MeshGateway` listener,
set the `crossMesh` property.

{% navtabs "environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshGateway
mesh: default
metadata:
  name: cross-mesh-gateway
  labels:
    kuma.io/mesh: default
spec:
  selectors:
    - match:
        kuma.io/service: cross-mesh-gateway{{ k8s_service_selector_suffix }}
  conf:
    listeners:
      - port: 8080
        protocol: HTTP
        crossMesh: true
        hostname: default.mesh
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: MeshGateway
mesh: default
name: cross-mesh-gateway
selectors:
  - match:
      kuma.io/service: cross-mesh-gateway
conf:
  listeners:
    - port: 8080
      protocol: HTTP
      crossMesh: true
      hostname: default.mesh
```

{% endnavtab %}
{% endnavtabs %}

#### Hostname

If the listener includes a `hostname` value,
the cross-mesh listener will be reachable
from all `Mesh`es at this `hostname` and `port`.
In this case, the URL `http://default.mesh:8080`.

Otherwise it will be reachable at the host:
`internal.<gateway-name>.<mesh-of-gateway-name>.mesh`.

#### Without transparent proxy

If transparent proxy isn't set up, you'll have to add the listener explicitly as
an outbound to your `Dataplane` objects if you want to access it:

```yaml
...
  outbound:
    - port: 8080
      tags:
        kuma.io/service: cross-mesh-gateway
        kuma.io/mesh: default
```

#### Limitations

The only `protocol` supported is `HTTP`.
Like service to service traffic,
all traffic to the gateway is protected with mTLS
but appears to be HTTP traffic
to the applications inside the mesh.
In the future, this limitation may be relaxed.

There can be only one entry in `selectors`
for a `MeshGateway` with `crossMesh: true`.

## All options

{% json_schema MeshGateway type=proto %}
