---
title: Authentication with the {{site.mesh_product_name}} API server
description: Authenticate users and automation tools to the control plane API server using user tokens, including token generation, rotation, and revocation.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

related_resources:
  - text: Manage secrets
    url: /mesh/manage-secrets/
  - text: Mesh ports
    url: /mesh/use-kuma/#control-plane-ports
  - text: Zone Ingress
    url: /mesh/zone-ingress/
---

{{site.mesh_product_name}} exposes its API server on [ports](/mesh/interact-with-control-plane/#control-plane-ports) `5681` and `5682`. An authenticated user can be authorized to execute administrative actions such as:
* Managing administrative resources like {{site.mesh_product_name}} secrets on Universal.
* Generating user tokens, data plane proxy tokens, zone ingress tokens, and zone tokens.

## User token

A user token is a signed JWT token that contains:
* The name of the user
* The list of groups that a user belongs to
* The expiration date of the token

### Groups

Groups in {{site.mesh_product_name}} allow you to manage API permissions for users. A user can be a part of multiple groups. 
{{site.mesh_product_name}} adds two groups to a user automatically:
* Authenticated users are added to `mesh-system:authenticated`.
* Unauthenticated users are added to `mesh-system:unauthenticated`.

### Admin user token

{{site.mesh_product_name}} creates an admin user token on the first start of the control plane.
The admin user token is a user token issued for users in the `mesh-system:admin` group.
This group is authorized by default to execute all administrative operations.

#### Configure kumactl with an admin user token

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}
1. Use `kubectl` to extract the admin token:

   ```sh
   kubectl get secret admin-user-token -n {{site.mesh_namespace}} {% raw %}--template={{.data.value}}{% endraw %} | base64 -d
   ```

1. Expose the {{site.mesh_product_name}} control plane to make it accessible from your machine using one of the following methods:
   * Port-forward port 5681.
   * Expose port 5681 and protect it with TLS or expose port 5682 with built-in via a load balancer.
   * Expose port 5681 using an `Ingress` (for example {{site.kic_product_name}}) and protect it with TLS.

1. Configure `kumactl` with the admin user token:
   ```sh
   kumactl config control-planes add \
     --name my-control-plane \
     --address https://$CONTROL_PLANE_ADDRESS:5682 \
     --auth-type=tokens \
     --auth-conf token=$GENERATED_TOKEN \
     --ca-cert-file=$CA_FILE_PATH
   ```

   {:.info}
   > If you are using the `5681` port, change the schema to `http://`. If you want to skip CP verification, use `--skip-verify` instead of `--ca-cert-file`.

{% endnavtab %}
{% navtab "Universal" %}
1. Run the following command on the machine where you deployed the control plane to generate the token:
   ```sh
   curl http://localhost:5681/global-secrets/admin-user-token | jq -r .data | base64 -d
   ```

1. Configure `kumactl` with admin user token
   ```sh
   kumactl config control-planes add \
     --name my-control-plane \
     --address https://$CONTROL_PLANE_ADDRESS:5682 \
     --auth-type=tokens \
     --auth-conf token=$GENERATED_TOKEN \
     --ca-cert-file=$CA_FILE_PATH
   ```

   {:.info}
   > If you are using the `5681` port, change the schema to `http://`. If you want to skip CP verification, use `--skip-verify` instead of `--ca-cert-file`.

1. Disable localhost as admin. By default, all requests originating from the localhost are authenticated as a `mesh-system:admin` user.
   After you retrieve and store the admin token, [configure a control plane](/mesh/control-plane-configuration/) with `KUMA_API_SERVER_AUTHN_LOCALHOST_IS_ADMIN` set to `false`.
{% endnavtab %}
{% endnavtabs %}

### Generate user tokens

To generate user tokens, you must provide the credentials of a user authorized to generate user tokens.
If you have configured `kumactl` with an admin user token, you can use the following command to create a user token:

```sh
kumactl generate user-token \
  --name john \
  --group team-a \
  --valid-for 24h
```

With the API, you must provide a token in the `Authorization` header:

```sh
curl localhost:5681/tokens/user \
  -H'authorization: Bearer eyJhbGc...' \
  -H'content-type: application/json' \
  --data '{"name": "john","groups": ["team-a"], "validFor": "24h"}' 
```

### Revoke user tokens

{{site.mesh_product_name}} doesn't keep a list of issued tokens. To invalidate a token, you must add it to the revocation list.

Every token has its own ID under the `jti` key.
You can extract the ID from the token using jwt.io or the [`jwt-cli`](https://www.npmjs.com/package/jwt-cli) tool.

To revoke user tokens, specify a comma-separated list of revoked IDs in a global secret named `user-token-revocations`.

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}
```sh
REVOCATIONS=$(echo '0e120ec9-6b42-495d-9758-07b59fe86fb9' | base64) && echo "apiVersion: v1
kind: Secret
metadata:
  name: user-token-revocations
  namespace: {{site.mesh_namespace}} 
data:
  value: $REVOCATIONS
type: system.kuma.io/global-secret" | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```sh
echo "
type: GlobalSecret
name: user-token-revocations
data: {{ revocations }}" | kumactl apply --var revocations=$(echo '0e120ec9-6b42-495d-9758-07b59fe86fb9' | base64) -f -
```
{% endnavtab %}
{% endnavtabs %}

### Rotate the signing key

A user token is signed by a signing key which is autogenerated on the first start of the control plane.

If the signing key is compromised, you must rotate it. You must also rotate all the tokens that were signed by it.

1. Generate a new signing key.
   The signing key is stored as a global secret named in the following format: `user-token-signing-key-<serial_number>`.

   When generating a new signing key, assign it a serial number greater than the current key's serial number.

{% capture navtabbed_content %}
{% navtabs "Environment" %}
{% navtab "Kubernetes" %}
Get the current key's serial number:
```sh
kubectl get secrets -n {{site.mesh_namespace}} --field-selector='type=system.kuma.io/global-secret'
NAME                       TYPE                           DATA   AGE
user-token-signing-key-1   system.kuma.io/global-secret   1      25m
```

In this example, the highest serial number is `1`. 

Generate a new signing key with a serial number of `2`:
```sh
TOKEN="$(kumactl generate signing-key)" && echo "
apiVersion: v1
data:
  value: $TOKEN
kind: Secret
metadata:
  name: user-token-signing-key-2
  namespace: {{site.mesh_namespace}}
type: system.kuma.io/global-secret
" | kubectl apply -f - 
```

{% endnavtab %}
{% navtab "Universal" %}
Get the current key's serial number:
```sh
kumactl get global-secrets
NAME                       AGE
user-token-signing-key-1   36m
```

In this example, the highest serial number is `1`. 

Generate a new signing key with a serial number of `2`:
```sh
echo "
type: GlobalSecret
name: user-token-signing-key-2
data: {{ key }}" | kumactl apply --var key=$(kumactl generate signing-key) -f -
```
{% endnavtab %}
{% endnavtabs %}
{% endcapture %}
{{ navtabbed_content | indent }}

2. [Generate new tokens](#generate-user-tokens).
   New tokens are generated with the signing key that has the highest serial number.
   At this point, tokens signed by either the new or old signing key are valid.

3. Remove the old signing key:
{% capture navtabbed_content %}
{% navtabs "Environment" %}
{% navtab "Kubernetes" %}
```sh
kubectl delete secret user-token-signing-key-1 -n {{site.mesh_namespace}}
```
{% endnavtab %}
{% navtab "Universal" %}
```sh
kumactl delete global-secret user-token-signing-key-1
```
{% endnavtab %}
{% endnavtabs %}
All new connections to the control plane now require tokens signed with
the new signing key.
{% endcapture %}
{{ navtabbed_content | indent }}

### Disable the admin user token

You can remove the default admin user token from storage and prevent it from being recreated.
Keep in mind that removing the admin user token doesn't remove the signing key.
Anyone with access to the signing key can generate a new admin token.

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}
1. Delete the `admin-user-token` secret
   ```sh
   kubectl delete secret admin-user-token -n kuma-namespace
   ```

1. Disable the token bootstrap by [configuring your control plane](/mesh/control-plane-configuration/) with the `KUMA_API_SERVER_AUTHN_TOKENS_BOOTSTRAP_ADMIN_TOKEN` variable set to `false`.
{% endnavtab %}
{% navtab "Universal" %}
1. Delete `admin-user-token` global secret:
   ```sh
   kumactl delete global-secret admin-user-token
   ```

2. Disable the token bootstrap by [configuring your control plane](/mesh/control-plane-configuration/) with the `KUMA_API_SERVER_AUTHN_TOKENS_BOOTSTRAP_ADMIN_TOKEN` variable set to `false`.
{% endnavtab %}
{% endnavtabs %}


## Offline token issuing

{% include /mesh/offline-token.md type="user" %}

## Multi-zone

In multi-zone mode, users execute a majority of actions on the global control plane.
However, some actions such as generating data plane tokens, are available on the zone control plane.
The global control plane doesn't propagate authentication credentials to the zone control plane.
You can set up consistent user tokens across the whole environment by manually copying signing keys from the global control plane to zone control planes. 
