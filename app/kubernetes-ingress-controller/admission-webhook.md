---
title: Admission Webhook

description: |
  What is the {{ site.kic_product_name }} admission webhook? How do I enable it? What does it validate?

content_type: reference
layout: reference

products:
  - kic

works_on:
  - on-prem
  - konnect
---

The {{site.kic_product_name}} ships with an admission webhook for KongPlugin and KongConsumer resources in the `configuration.konghq.com` API group.  You can generate TLS certificate and key pair that you need for admission webhook.

The admission webhook is enabled by default when installing {{ site.kic_product_name }} via the Helm chart. To disable the webhook set `ingressController.admissionWebhook.enabled=false` in your `values.yaml`.

{:.warning}
> The admission webhook should not be disabled unless you are asked to do so by a member of the Kong team.

## Test the configuration
You can test if the admission webhook is enabled for duplicate KongConsumers, incorrect KongPlugins, incorrect credential secrets, and incorrect routes.

### Verify duplicate KongConsumers

1. Create a KongConsumer with username as `alice`:

    ```bash
    echo "apiVersion: configuration.konghq.com/v1
    kind: KongConsumer
    metadata:
      name: alice
      annotations:
        kubernetes.io/ingress.class: kong
    username: alice" | kubectl apply -f -
    ```
    The results should look like this:
    ```
    kongconsumer.configuration.konghq.com/alice created
    ```

1. Create another KongConsumer with the same username:

    ```bash
    echo "apiVersion: configuration.konghq.com/v1
    kind: KongConsumer
    metadata:
      name: alice2
      annotations:
        kubernetes.io/ingress.class: kong
    username: alice" | kubectl apply -f -
    ```
    The results should look like this:
    ```
    Error from server: error when creating "STDIN": admission webhook "validations.kong.konghq.com" denied the request: consumer already exists
    ```

The validation webhook rejected the KongConsumer resource as there already exists a consumer in Kong with the same username.

### Verify incorrect KongPlugins

Invalid plugin configurations are rejected by the admission webhook. This example adds an additional `foo` parameter to the `correlation-id` plugin, which is not a valid configuration.  If you remove the `foo: bar` configuration line, the plugin will be created successfully.

```bash
echo "
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: request-id
config:
  foo: bar
  header_name: my-request-id
plugin: correlation-id
" | kubectl apply -f -
```
The results should look like this:
```
Error from server: error when creating "STDIN": admission webhook "validations.kong.konghq.com" denied the request: plugin failed schema validation: schema violation (config.foo: unknown field)
```

### Verify incorrect credential secrets

The admission webhook validates that credential secrets contain all required fields.

```bash
echo '
apiVersion: v1
kind: Secret
metadata:
  name: missing-password-credential
  labels:
    konghq.com/credential: basic-auth
stringData:
  username: foo
' | kubectl apply -f -
```
The results should look like this:
```
Error from server: "STDIN": error when creating "STDIN": admission webhook "validations.kong.konghq.com" denied the request: consumer credential failed validation: missing required field(s): password
```

The admission webhook also validates the credential type.

```bash
echo '
apiVersion: v1
kind: Secret
metadata:
  name: wrong-cred-credential
  labels:
    konghq.com/credential: wrong-auth
stringData:
  sdfkey: my-sooper-secret-key
' | kubectl apply -f -
```
The results should look like this:
```
Error from server: error when creating "STDIN": admission webhook "validations.kong.konghq.com" denied the request: consumer credential failed validation: invalid credential type wrong-auth
```

### Verify incorrect routes

Invalid routing rules are rejected by the admission webhook. Here is an example with an invalid regular expression:

{% navtabs route %}
{% navtab "Gateway API" %}
```bash
echo 'apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: echo-httproute
spec:
  parentRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: kong
  rules:
    - matches:
        - path:
            type: RegularExpression
            value: /echo/**/broken
      backendRefs:
        - name: echo
          port: 1027' | kubectl apply -f -
```
The results should look like this:
```
Error from server: error when creating "STDIN": admission webhook "validations.kong.konghq.com" denied the request: HTTPRoute failed schema validation: schema violation (paths.1: invalid regex: '/echo/**/broken' (PCRE returned: pcre_compile() failed: nothing to repeat in "/echo/**/broken" at "*/broken"))
```
{% endnavtab %}
{% navtab "Ingress" %}
```bash
echo 'apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo
  annotations:
    konghq.com/strip-path: "true"
spec:
  ingressClassName: kong
  rules:
    - http:
        paths:
          - path: /~/echo/**/broken
            pathType: ImplementationSpecific
            backend:
              service:
                name: echo
                port:
                  number: 1025' | kubectl apply -f -
```
The results should look like this:
```
Error from server: error when creating "STDIN": admission webhook "validations.kong.konghq.com" denied the request: Ingress failed schema validation: schema violation (paths.1: invalid regex: '/echo/**/broken' (PCRE returned: pcre_compile() failed: nothing to repeat in "/echo/**/broken" at "*/broken"))
```
{% endnavtab %}
{% endnavtabs %}
