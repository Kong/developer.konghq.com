---
title: "Multi-zone authentication"
description: "Use Control Plane scoped tokens to authenticate zone Control Planes in a multi-zone {{site.mesh_product_name}} deployment."
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/
works_on:
  - on-prem
  - konnect
tags:
  - multi-zone
  - authentication
  - zone-tokens
  - kds
search_aliases:
  - kds-auth

related_resources:
  - text: Multi-zone deployment
    url: /mesh/mesh-multizone-service-deployment/
---


## How does multi-zone authentication work?

To add to the security of your deployments, {{site.mesh_product_name}} provides authentication of zone Control Planes to the global Control Plane. Authentication is based on the Zone Token which is also used to authenticate the zone proxy.
See [zone proxy authentication](/mesh/zone-proxy-auth/) to learn about token characteristics, revocation, rotation, and more.
To enable authentication between Control Planes:

* Generate a token for each Zone Control Plane with the `cp` scope.
* Pass the token to the Zone Control Plane.
* Enable authentication on the Global Control Plane.

### Generate the token

On the global Control Plane, run the following command to store the token in `/tmp/token`:

```sh
kumactl generate zone-token --zone=west --scope=cp --valid-for=720h > /tmp/token
```

### Add tokens to zones

{% navtabs "add tokens" %}
{% navtab "Kubernetes with kumactl" %}

If you install the zone Control Plane with `kumactl install control-plane`, pass the `--cp-token-path` argument, where the value is the path to the file where the token is stored:

```sh
kumactl install control-plane \
  --mode=zone \
  --zone=$ZONE-NAME \
  --cp-token-path=/tmp/token \
  --ingress-enabled \
  --kds-global-address grpcs://$GLOBAL-KDS-ADDRESS:5685 | kubectl apply -f -
```

{% endnavtab %}
{% navtab "Kubernetes with Helm" %}

Create a secret with a token in the same namespace where {{site.mesh_product_name}} is installed:

```sh
kubectl create secret generic cp-token -n kong-mesh-system --from-file=/tmp/token
```

Add the following to `Values.yaml`:

```yaml
kuma:
  controlPlane:
    secrets:
      - Env: "KMESH_MULTIZONE_ZONE_KDS_AUTH_CP_TOKEN_INLINE"
        Secret: "cp-token"
        Key: "token"
```

Install the zone control plane:

```sh
helm --create-namespace --namespace kong-mesh-system kong-mesh kong-mesh/kong-mesh -f Values.yaml 
```

{% endnavtab %}
{% navtab "Universal" %}

Set the token as an inline value in a `KMESH_MULTIZONE_ZONE_KDS_AUTH_CP_TOKEN_INLINE` environment variable:

```sh
KUMA_MODE=zone \
KUMA_MULTIZONE_ZONE_NAME="YOUR-ZONE-NAME" \
KUMA_MULTIZONE_ZONE_GLOBAL_ADDRESS="grpcs://EXAMPLE-GLOBAL-KDS-ADDRESS" \
KMESH_MULTIZONE_ZONE_KDS_AUTH_CP_TOKEN_INLINE="eyJhbGciOiJSUzI1NiIsImtpZCI6IjEiLCJ0eXAiOiJKV1QifQ.eyJab25lIjoid2VzdCIsIlNjb3BlIjpbImNwIl0sImV4cCI6MTY2OTU0NjkzOSwibmJmIjoxNjY2OTU0NjM5LCJpYXQiOjE2NjY5NTQ5MzksImp0aSI6IjZiYWYyYzkwLTBlODYtNGM2Mi05N2E3LTc4MzU4NTU4MzRiYyJ9.DJfA0M6uUfO4oytp8jHtzngiVggQWQR88YQxWVU1ujc0Zv-XStRDwvpdEoFGOzWVn4EUfI3gcv9qS2MxqIzQjJ83k5Jq85w4hkPyLGr-0jNS1UZF6yXz7lB_As8f91gMVHbRAoFuoybV5ndDtfYzwZknyzott7doxk-SjTes2GDvpg0-kFNGc4MBR2EprGl7YKO0vhFxQjln5AyCAhmAA7-PM7WRCzhmS-pUXacfZtP2VulWYhmTAuLPnkJrJN-ZWPkIpnV1MZmsgWbzTpnW-PhmCMQfD5m2im1c_3OlFwa9P9rZQQhdhbTp0ofMvW-cdCAcG_lOJI5j60cqPh2DGg" \
./kuma-cp run
```

{% endnavtab %}
{% endnavtabs %}
### Enable authentication

If you are starting from scratch and not securing an existing {{site.mesh_product_name}} deployment, you can do this as a first step.

{% navtabs "authentication" %}
{% navtab "Kubernetes with kumactl" %}

If you install the zone Control Plane with `kumactl install control-plane`, pass the `--cp-auth` argument with the value `cpToken`:

```sh
kumactl install control-plane \
  --mode=global \
  --cp-auth=cpToken | kubectl apply -f -
```

{% endnavtab %}
{% navtab "Kubernetes with Helm" %}

Add the following to `Values.yaml`:

```yaml
kuma:
  controlPlane:
    envVars:
      KMESH_MULTIZONE_GLOBAL_KDS_AUTH_TYPE: cpToken
```

{% endnavtab %}
{% navtab "Universal" %}

Set `KMESH_MULTIZONE_GLOBAL_KDS_AUTH_TYPE` to `cpToken`:

```sh
KUMA_MODE=global \
KMESH_MULTIZONE_GLOBAL_KDS_AUTH_TYPE=cpToken \
./kuma-cp run
```

{% endnavtab %}
{% endnavtabs %}

Verify the zone Control Plane is connected with authentication by looking at the global Control Plane logs:

```
2021-02-24T14:30:38.596+0100	INFO	kds.auth	Zone CP successfully authenticated	{"zone": "cluster-2"}
```

## Additional security

By default, a connection from the zone Control Plane to the global Control Plane is secured with TLS.