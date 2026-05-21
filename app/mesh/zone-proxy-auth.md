---
title: Zone proxy authentication
description: Learn about authentication for zone proxies using service account tokens or zone tokens for secure control plane communication.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

related_resources:
  - text: Multi-zone deployment
    url: '/mesh/mesh-multizone-service-deployment/'
  - text: Zone ingress
    url: /mesh/zone-ingress/
  - text: Zone egress
    url: /mesh/zone-egress/
---

To obtain a configuration from the control plane, a zone proxy ([zone ingress](/mesh/zone-ingress/) or [zone egress](/mesh/zone-egress/)) must authenticate itself.
You can do this using:

* A [service account token](#service-account-token) on Kubernetes
* A [zone token](#zone-token) on Universal

## Service account token

On Kubernetes, a zone proxy authenticates by leveraging the [`ServiceAccountToken`](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/#bound-service-account-token-volume) that is mounted in every Pod.

## Zone token

On Universal, a zone proxy must be explicitly configured with a unique security token with the appropriate scope (`egress` or `ingress`).

The zone token used to identify zone proxies is a [JWT token](https://jwt.io) that contains:
* The zone in which zone proxy operates
* The expiration date of the token (10 years by default)
* The scope as a list of proxies for which the token is valid (`egress` and `ingress` by default)

The zone token is signed using a key that the control plane autogenerates on first startup. Tokens themselves are never stored in the control plane. Only the signing keys are stored, and these are used to verify token validity. The signing algorithm is RS256.

You can use the following command to check for the signing key:
```sh
kumactl get global-secrets
```

You should get the following result:
```
NAME                       AGE
zone-token-signing-key-1   7s
```
{:.no-copy-code}

### Generate a zone token

{% navtabs "Tool" %}
{% navtab "kumactl" %}
Use the following command to generate a token with `kumactl`:
```bash
kumactl generate zone-token \
  --zone us-east \
  --scope egress \
  --valid-for 720h > /tmp/kuma-zone-proxy-token
```
{% endnavtab %}
{% navtab "REST API" %}
Use the following command to generate the token with the REST API:
```bash
curl -XPOST \
  -H "Content-Type: application/json" \
  --data '{"zone": "us-east", "validFor": "720h", "scope": ["egress", "ingress"]}' \
  http://localhost:5681/tokens/zone > /tmp/kuma-zone-proxy-token
```
{% endnavtab %}
{% endnavtabs %}

The token should be stored in a file and then passed when you start `kuma-dp`:
```bash
kuma-dp run \
  --proxy-type=ingress # or egress \
  --dataplane-file=zone-proxy-definition.yaml
  --cp-address=https://127.0.0.1:5678 \
  --dataplane-token-file=/tmp/kuma-zone-proxy-token
```

You can also pass the token as a `KUMA_DATAPLANE_RUNTIME_TOKEN` environment variable.

## Revoke a token

{% include /mesh/token-revocation.md type="zone" %}

## Rotate a signing key

{% include /mesh/signing-key-rotation.md type="zone" %}


## Offline token issuing

{% include /mesh/offline-token.md type="zone" %}


## Multi-zone

When running in multi-zone mode, you can only generate zone tokens on the global control plane. 
The zone control plane only has a public key signing key to verify tokens.

## Disable zone proxy authentication
You can turn off authentication by setting `KUMA_DP_SERVER_AUTH_TYPE` to `none`.

{:.danger}
> Do not disable authentication between the control plane and data plane proxies in production. 
> Without authentication, any data plane proxy can impersonate any service, allowing unauthorized access to your mesh.
