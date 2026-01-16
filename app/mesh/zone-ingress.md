---  
title: '{{site.mesh_product_name}} zone ingress'
description: Configure ZoneIngress proxies to enable cross-zone communication in multi-zone deployments.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

related_resources:
  - text: Zone Egress
    url: /mesh/zone-egress/
  - text: MeshMultiZoneService
    url: /mesh/meshmultizoneservice/
  - text: '{{site.mesh_product_name}} data plane on Kubernetes'
    url: /mesh/data-plane-kubernetes/
  - text: "{{ site.mesh_product_name }} data plane proxy"
    url: /mesh/data-plane-proxy/
  - text: "{{site.mesh_product_name}} data plane on Universal"
    url: /mesh/data-plane-universal/
---

In a [multi-zone deployment](/mesh/mesh-multizone-service-deployment/), you can use the `ZoneIngress` proxy to manage cross-zone communication.
These proxies are not attached to any specific workloads, they are bound to a specific zone.
A zone ingress can proxy traffic between all meshes, so you only need one deployment in each zone. 

All requests that are sent from one zone to another will be directed to the proper instance by the zone ingress.

{:.info}
> Since the `ZoneIngress` proxy uses [Server Name Indication (SNI)](https://en.wikipedia.org/wiki/Server_Name_Indication) to route traffic, [mTLS](/mesh/policies/mutual-tls/) is required to handle cross-zone communication.

The `ZoneIngress` entity includes the following parameters:

* `type`: Must be `ZoneIngress`.
* `name`: The name of the zone ingress instance, it must be unique for any given zone.
* `networking`: The networking parameters of the zone ingress.
    * `address`: The address of the network interface that the zone ingress is listening on. It can be the address of either
      the public or private network interface, but the latter must be used with a load balancer.
    * `port`: The port that the zone ingress is listening on. The default is `10001`.
    * `advertisedAddress`: An IP address or hostname that will be used to communicate with the zone ingress. The zone ingress
      doesn't listen on this address. If the zone ingress is exposed using a load balancer, then the address of the load balancer
      should be used. If the zone ingress is listening on the public network interface, then the address of the public network
      interface should be used.
    * `advertisedPort`: A port that will be used to communicate with the zone ingress. The zone ingress doesn't listen on this port.
    * `admin`: The parameters related to the Envoy Admin API.
      * `port`: The port that the Envoy Admin API will listen to.
* `availableServices` The list of services that could be consumed through the zone ingress. This is auto-generated on the {{site.mesh_product_name}} control plane.
* `zone`: The zone where the zone ingress is running. This is auto-generated on the {{site.mesh_product_name}} control plane.

The `advertisedAddress` and `advertisedPort` parameters are required to allow data plane proxies from other zones to access the zone ingress. If a zone ingress doesn't have values set for these fields, it's not taken into account in the Envoy configuration.

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}
To install the `ZoneIngress` proxy in Kubernetes:
* With kumactl, add the `--ingress-enabled` flag to your `kumactl install control-plane` command.
* With Helm, add the `{{site.set_flag_values_prefix}}ingress.enabled: true` parameter to your `values.yaml`.

{{site.mesh_product_name}} sets `advertisedAddress` and `advertisedPort` automatically by checking the Service associated with the zone ingress.

If the Service type is Load Balancer, {{site.mesh_product_name}} will wait for public IP to be resolved. It may take a couple of minutes to receive public IP depending on the LB implementation of your Kubernetes provider.
If the Service type is Node Port, {{site.mesh_product_name}} will take an external IP of the first Node in the cluster and combine it with the Node Port.

You can provide your own public address and port using the following annotations on the ingress deployment:
* `kuma.io/ingress-public-address`
* `kuma.io/ingress-public-port`

{% endnavtab %}
{% navtab "Universal" %}

In Universal mode, a token is required to authenticate the `ZoneIngress` instance. Create the token with `kumactl`:

```bash
kumactl generate zone-token --valid-for 720h --scope ingress > $TOKEN_FILE
```

Create a `ZoneIngress` configuration to allow services to receive traffic from other zones:

```yaml
type: ZoneIngress
name: zoneingress-1
networking:
  address: 192.168.0.1
  port: 10001
  advertisedAddress: 10.0.0.1 # Adapt to the address of the load balancer in front of your ZoneIngress
  advertisedPort: 10001 # Adapt to the port of the load balancer in front of you ZoneIngress
```

Apply the zone ingress configuration, passing the IP address of the control plane:

```sh
kuma-dp run \
--proxy-type=ingress \
--cp-address=https://$CP_IP_ADDRESS:5678 \
--dataplane-token-file=$TOKEN_FILE \
--dataplane-file=$CONFIG_FILE
```

{% endnavtab %}
{% endnavtabs %}

A `ZoneIngress` deployment can be scaled horizontally. Many instances can have the same advertised address and advertised port because they can be behind one load balancer.
