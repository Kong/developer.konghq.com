---
title: 'Zone egress'
description: Configure ZoneEgress proxies to isolate outgoing traffic to other zones or external services.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

related_resources:
    - text: Zone ingress
      url: /mesh/zone-ingress/
    - text: MeshMultiZoneService
      url: /mesh/meshmultizoneservice/
---

The `ZoneEgress` proxy is used to isolate outgoing traffic to Services in other zones or [external Services](/mesh/policies/external-services/) in the local zone.

{:.info}
> Since the `ZoneEgress` proxy uses [Server Name Indication (SNI)](https://en.wikipedia.org/wiki/Server_Name_Indication) to route traffic, [mTLS](/mesh/policies/mutual-tls/) is required.

This proxy is not attached to any specific workloads, it's bound to a specific zone.
A zone egress can proxy traffic between all meshes, so you only need one deployment in each zone.

When a zone egress is present:
* In a multi-zone deployment, all requests sent from local data plane proxies to other zones will be directed through the local zone egress instance, which will then direct the traffic to the proper instance of the [zone ingress](/mesh/zone-ingress/).
* All requests that are sent from local data plane proxies to external Services available within the zone will be directed through the local zone egress instance.

{:.info}
> The `ZoneEgress` proxy currently is an optional component.
> In the future it will become required for using external services.

The `ZoneEgress` entity includes the following parameters:

* `type`: Must be `ZoneEgress`.
* `name`: The name of the `ZoneEgress` instance, it must be unique for any given `zone`.
* `networking`: The networking parameters of the zone egress.
    * `address`: The address of the network interface that the zone egress is listening on.
    * `port`: The port that zone egress is listening on.
    * `admin`: The parameters related to the Envoy Admin API.
      * `port`: The port that the Envoy Admin API will listen to.
* `zone`: The zone that the zone egress belongs to. This is auto-generated on the {{site.mesh_product_name}} control plane.

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}

To install the `ZoneEgress` proxy in Kubernetes:
* With kumactl, add the `--egress-enabled` flag to your `kumactl install control-plane` command.
* With Helm, add the `{{site.set_flag_values_prefix}}egress.enabled: true` parameter to your `values.yaml`.

{% endnavtab %}
{% navtab "Universal" %}

In Universal mode, a token is required to authenticate the `ZoneEgress` instance. Create the token with `kumactl`:

```bash
kumactl generate zone-token --valid-for 720h --scope egress > $TOKEN_FILE
```

Create a `ZoneEgress` configuration to allow `kuma-cp` Services to proxy traffic to other zones or external Services:

```yaml
type: ZoneEgress
name: zoneegress-1
networking:
  address: 192.168.0.1
  port: 10002
```

Apply the zone egress configuration, passing the IP address of the control plane:

```bash
kuma-dp run \
--proxy-type=egress \
--cp-address=https://$CP_IP_ADRESS:5678 \
--dataplane-token-file=$TOKEN_FILE \
--dataplane-file=$CONFIG_FILE
```

{% endnavtab %}
{% endnavtabs %}


A `ZoneEgress` deployment can be scaled horizontally.

In addition to mTLS, there's a configuration in the `Mesh` resource to route traffic through the `ZoneEgress`:

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  routing:
    zoneEgress: true
  mtls: # mTLS is required to use ZoneEgress
    [...]" | kubectl apply -f -
```

{% endnavtab %}
{% navtab "Universal" %}

```shell
cat <<EOF | kumactl apply -f -
type: Mesh
name: default
mtls: # mTLS is required to use ZoneEgress
  [...]
routing:
  zoneEgress: true
EOF
```

{% endnavtab %}
{% endnavtabs %}

This configuration will force cross zone communication and external services to go through `ZoneEgress`.
If enabled but no `ZoneEgress` is available the communication will fail.
