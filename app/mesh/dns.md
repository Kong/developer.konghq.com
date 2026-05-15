---
title: DNS
description: Learn how {{site.mesh_product_name}} DNS works with virtual IPs and service naming to enable transparent proxying.
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/
related_resources:
  - text: Configure the {{site.mesh_product_name}} CNI
    url: '/mesh/cni/'
  - text: Transparent proxying
    url: '/mesh/transparent-proxying/'
  - text: Kubernetes annotations and labels
    url: /mesh/annotations/
  - text: Concepts
    url: /mesh/concepts/
  - text: Service discovery
    url: /mesh/service-discovery/

min_version:
  mesh: '2.9'
---

{{site.mesh_product_name}} ships with a DNS resolver that provides service naming: a mapping of hostnames to virtual IPs (VIPs) of services registered in {{site.mesh_product_name}}.

{{site.mesh_product_name}} DNS is only relevant when you use [transparent proxying](/mesh/transparent-proxying/).

## How it works

The {{site.mesh_product_name}} DNS server responds to `A` and `AAAA` DNS requests with `A` or `AAAA` records. For example: `redis.mesh. 60 IN A 240.0.0.100` or `redis.mesh. 60 IN AAAA fd00:fd00::100`.

The control plane allocates virtual IPs from the configured CIDR (`240.0.0.0/4` by default) by constantly scanning the services available in all {{site.mesh_product_name}} meshes. When a service is removed, the control plane frees its VIP, and {{site.mesh_product_name}} DNS stops responding for it with `A` and `AAAA` records. Virtual IPs are stable and replicated between instances of the control plane and data plane proxies.

When the control plane allocates a new VIP or frees an old one, it pushes the change to the data plane proxy.

The data plane proxy handles all name lookups locally, not the control plane. This approach makes name resolution more robust. For example, if the control plane is down, a data plane proxy can still resolve DNS.

The data plane proxy DNS consists of:

- An Envoy DNS filter that provides responses from the mesh for DNS records
- A CoreDNS instance launched by `kuma-dp` that sends requests between the Envoy DNS filter and the original host DNS
- `iptables` rules that redirect the original DNS traffic to the local CoreDNS instance

Because DNS requests go to the Envoy DNS filter first, any DNS name that exists inside the mesh always resolves to the mesh address. In practice, a DNS name present in the mesh shadows equivalent names that exist outside the mesh.

{{site.mesh_product_name}} DNS is not a service discovery mechanism: it does not return the real IP addresses of service instances. Instead, it always returns a single VIP assigned to the relevant service in the mesh. This single-VIP approach provides a unified view of all services within a single zone or across multiple zones.

The default TTL is 60 seconds, which ensures the client synchronizes with {{site.mesh_product_name}} DNS and accounts for any intervening changes.

### Naming

By default, {{site.mesh_product_name}} generates domain names in the format `<kuma.io/service tag>.mesh`, accessible on port `80`.

If you use [`MeshService`](/mesh/meshservice/), [`MeshExternalService`](/mesh/meshexternalservice/), or [`MeshMultiZoneService`](/mesh/meshmultizoneservice/), {{site.mesh_product_name}} generates the domains using a [`HostnameGenerator`](/mesh/hostnamegenerator/).

## Installation

On Kubernetes, {{site.mesh_product_name}} DNS is enabled by default whenever the `kuma-dp` sidecar proxy is injected.

On Universal, follow the instructions in [transparent proxying](/mesh/transparent-proxying/).

### Special considerations

{{site.mesh_product_name}} DNS uses advanced networking techniques. In mixed IPv4 and IPv6 environments, we recommend specifying an [IPv6 virtual IP CIDR](/mesh/ipv6-support/) so DNS responses work consistently across both stacks.

### Overriding the CoreDNS configuration

In some cases, you may want to override the default CoreDNS configuration.

{{site.mesh_product_name}} supports overriding the CoreDNS configuration from the control plane for both Kubernetes and Universal installations. For Universal installations, {{site.mesh_product_name}} also supports overriding from data planes. When you override from the control plane, all data planes in the mesh use the overridden DNS configuration.

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}
Only overriding from the control plane is supported.

To override the configuration, [configure](/mesh/reference/kuma-cp/) the bootstrap server in `kuma-cp`:

```yaml
bootstrapServer:
  corefileTemplatePath: "/path/to/mounted-corefile-template" # ENV: KUMA_BOOTSTRAP_SERVER_PARAMS_COREFILE_TEMPLATE_PATH
```

You also need to mount the DNS configuration template file into the control plane by adding an extra ConfigMap. Create the ConfigMap in the namespace where the control plane is installed. Make sure the file exists on disk:

```sh
kubectl create --namespace {{site.mesh_namespace}} configmap corefile-template \
  --from-file corefile-template=/path/to/corefile-template-on-disk
```

Point to this ConfigMap when installing {{site.mesh_product_name}}:

```sh
helm install --namespace {{site.mesh_namespace}} \
  --set "{{site.set_flag_values_prefix}}controlPlane.envVars.KUMA_BOOTSTRAP_SERVER_PARAMS_COREFILE_TEMPLATE_PATH=/path/to/mounted-corefile-template" \
  --set "{{site.set_flag_values_prefix}}controlPlane.extraConfigMaps[0].name=corefile-template" \
  --set "{{site.set_flag_values_prefix}}controlPlane.extraConfigMaps[0].mountPath=/path/to/mounted-corefile-template/corefile-template" \
  {{site.mesh_helm_install_name}} {{site.mesh_helm_repo}}
```

{% endnavtab %}
{% navtab "Universal" %}
Both overriding from the control plane and data planes are supported.

To override DNS configuration from the control plane, you can [configure](/mesh/reference/kuma-cp/) the bootstrap server in `kuma-cp`:

```yaml
bootstrapServer:
  corefileTemplatePath: "/path/to/mounted-corefile-template" # ENV: KUMA_BOOTSTRAP_SERVER_PARAMS_COREFILE_TEMPLATE_PATH
```

Make sure the file path exists on disk.

To override DNS configuration from data planes, use `--dns-coredns-config-template-path` as an argument to `kuma-dp`. If the data plane connects to a control plane that also has the DNS configuration overridden, the data plane override takes precedence.

{% endnavtab %}
{% endnavtabs %}

To override the configuration, prepare a DNS configuration file. The file is a [CoreDNS configuration](https://coredns.io/manual/toc/) that {{site.mesh_product_name}} processes as a Go template.

Base your edits on [the existing default configuration](https://github.com/kumahq/kuma/blob/master/app/kuma-dp/pkg/dataplane/dnsserver/Corefile). For example, use the following configuration to make the DNS server return `NOERROR` instead of an error for IPv6 queries when your cluster has IPv6 disabled:

{% raw %}

```text
.:{{ .CoreDNSPort }} {
    # add a plugin to return NOERROR for IPv6 queries
    template IN AAAA . {
       rcode NOERROR
       fallthrough
    }

    forward . 127.0.0.1:{{ .EnvoyDNSPort }}
    # We want all requests to be sent to the Envoy DNS Filter, unsuccessful responses should be forwarded to the original DNS server.
    # For example: requests other than A, AAAA and SRV will return NOTIMP when hitting the envoy filter and should be sent to the original DNS server.
    # Codes from: https://github.com/miekg/dns/blob/master/msg.go#L138
    alternate NOTIMP,FORMERR,NXDOMAIN,SERVFAIL,REFUSED . /etc/resolv.conf
    prometheus localhost:{{ .PrometheusPort }}
    errors
}
```

{% endraw %}

## Configuration

You can [configure](/mesh/reference/kuma-cp/) {{site.mesh_product_name}} DNS in `kuma-cp`:

```yaml
dnsServer:
  CIDR: "240.0.0.0/4" # ENV: KUMA_DNS_SERVER_CIDR
  domain: "mesh" # ENV: KUMA_DNS_SERVER_DOMAIN
  serviceVipEnabled: true # ENV: KUMA_DNS_SERVER_SERVICE_VIP_ENABLED
```

The `CIDR` field sets the IP range of virtual IPs. The default `240.0.0.0/4` is reserved for future IPv4 use and is guaranteed to be non-routable. We don't recommend changing this value because the default range is guaranteed to avoid conflicts with routable IPs.

The `domain` field specifies the default `.mesh` DNS zone that {{site.mesh_product_name}} DNS resolves. This field is only relevant when `serviceVipEnabled` is set to `true`.

The `serviceVipEnabled` field defines whether a VIP is generated for each `kuma.io/service`.

## Usage

To consume a service handled by {{site.mesh_product_name}} DNS, whether from a {{site.mesh_product_name}}-enabled Pod on Kubernetes or a VM with `kuma-dp`, use the automatically generated `kuma.io/service` tag. The resulting domain name has the format `{service tag}.mesh`. For example, from inside a {{site.mesh_product_name}}-enabled Pod:

```sh
curl http://echo-server_echo-example_svc_1010.mesh:80
```

```sh
curl http://echo-server_echo-example_svc_1010.mesh
```

You can also use a [DNS RFC1035 compliant name](https://www.ietf.org/rfc/rfc1035.txt) by replacing the underscores in the service name with dots. For example:

```sh
curl http://echo-server.echo-example.svc.1010.mesh:80
```

```sh
curl http://echo-server.echo-example.svc.1010.mesh
```

The default listeners created on the VIP listen on port `80`, so you can omit the port when you use a standard HTTP client.

{{site.mesh_product_name}} DNS allocates a VIP for every service within a mesh and creates an outbound virtual listener for every VIP. If you inspect the result of `curl localhost:9901/config_dump`, you can see something like this:

```json
    {
     "name": "outbound:240.0.0.1:80",
     "active_state": {
      "version_info": "51adf4e6-287e-491a-9ae2-e6eeaec4e982",
      "listener": {
       "@type": "type.googleapis.com/envoy.api.v2.Listener",
       "name": "outbound:240.0.0.1:80",
       "address": {
        "socket_address": {
         "address": "240.0.0.1",
         "port_value": 80
        }
       },
       "filter_chains": [
        {
         "filters": [
          {
           "name": "envoy.filters.network.tcp_proxy",
           "typed_config": {
            "@type": "type.googleapis.com/envoy.config.filter.network.tcp_proxy.v2.TcpProxy",
            "stat_prefix": "echo-server_kuma-test_svc_80",
            "cluster": "echo-server_kuma-test_svc_80"
           }
          }
         ]
        }
       ],
       "deprecated_v1": {
        "bind_to_port": false
       },
       "traffic_direction": "OUTBOUND"
      },
      "last_updated": "2020-07-06T14:32:59.732Z"
     }
    }
```
