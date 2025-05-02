---
title: deck file kong2kic
description: Convert a Kong declarative configuration file to {{site.kic_product_name}} compatible CRDs. Supports both Gateway API and Ingress resources.

content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - deck

breadcrumbs:
  - /deck/
  - /deck/file/

related_resources:
  - text: "{{ site.kic_product_name }}"
    url: /kubernetes-ingress-controller/

tags:
  - declarative-config
  - kubernetes
---

The `kong2kic` command converts a {{ site.base_gateway }} declarative configuration file in to Kubernetes CRDs that can be used with the [{{ site.kic_product_name }}](/kubernetes-ingress-controller/).

`kong2kic` generates Gateway API `HTTPRoute` resources by default. If you're using `ingress` resources, you can specify the `--ingress` flag.

Consumers, Consumer Groups, Plugins, and other supported Kong entities are converted to the related `Kong` prefixed resources, such as `KongConsumer`.

```bash
deck file kong2kic -s kong.yaml -o k8s.yaml
```

The following table details how Kong configuration entities are mapped to Kubernetes manifests:

<!--vale off-->
{% table %}
columns:
  - title: decK entity
    key: deck_entity
  - title: K8s entity
    key: k8s_entity
rows:
  - deck_entity: Service
    k8s_entity: Service with annotations and KongIngress for upstream section
  - deck_entity: Route
    k8s_entity: "Ingress (Ingress API) or HTTPRoute (Gateway API) with annotations"
  - deck_entity: Global Plugin
    k8s_entity: KongClusterPlugin
  - deck_entity: Plugin
    k8s_entity: KongPlugin
  - deck_entity: "Auth Plugins (`key-auth`, `hmac-auth`, `jwt`, `basic-auth`, `oauth2`, `acl`, `mtls-auth`)"
    k8s_entity: KongPlugin and Secret with credentials section in KongConsumer
  - deck_entity: Upstream
    k8s_entity: KongIngress or kongUpstreamPolicy
  - deck_entity: Consumer
    k8s_entity: KongConsumer
  - deck_entity: ConsumerGroup
    k8s_entity: KongConsumerGroup
  - deck_entity: Certificate
    k8s_entity: "`kubernetes.io/tls` Secret"
  - deck_entity: CA Certificate
    k8s_entity: generic Secret
{% endtable %}
<!--vale on-->

## Configuration options

The table below shows the most commonly used configuration options. For a complete list, run `deck file kong2kic --help`.

<!--vale off-->
{% table %}
columns:
  - title: Flag
    key: flag
  - title: Description
    key: description
  - title: Default
    key: default
rows:
  - flag: "`--class-name`"
    description: |
      Value to use for `"kubernetes.io/ingress.class"` (ingress) and for `"parentRefs.name"` (HTTPRoute).
    default: "`kong`"
  - flag: "`--format`"
    description: "Output file format: `json` or `yaml`."
    default: "`yaml`"
  - flag: "`--ingress`"
    description: Use Kubernetes Ingress API manifests instead of Gateway API manifests.
    default: "N/A"
  - flag: "`--kic-version`"
    description: Generate manifests for KIC v3 or v2. Possible values are 2 or 3.
    default: "3"
{% endtable %}
<!--vale on-->

## kong2kic conversion example

Let's see an example of how the following decK state file is converted to Ingress API Kubernetes
manifests and Gateway API Kubernetes manifests.

{% navtabs "deck-kong2kic" %}
{% navtab "decK state file "%}

```yaml
services:
  - name: example-service
    url: http://example-api.com
    protocol: http
    host: example-api.com
    port: 80
    path: /v1
    retries: 5
    connect_timeout: 5000
    write_timeout: 60000
    read_timeout: 60000
    enabled: true
    plugins:
      - name: rate-limiting-advanced
        config:
          limit:
            - 5
          window_size:
            - 30
          identifier: consumer
          sync_rate: -1
          namespace: example_namespace
          strategy: local
          hide_client_headers: false
    routes:
      - name: example-route
        methods:
          - GET
          - POST
        hosts:
          - example.com
          - another-example.com
          - yet-another-example.com
        paths:
          - ~/v1/example/?$
          - /v1/another-example
          - /v1/yet-another-example
        protocols:
          - http
          - https
        headers:
          x-my-header:
            - ~*foos?bar$
          x-another-header:
            - first-header-value
            - second-header-value
        regex_priority: 1
        strip_path: false
        preserve_host: true
        https_redirect_status_code: 302
        snis:
          - example.com
        sources:
          - ip: 192.168.0.1
        plugins:
          - name: cors
            config:
              origins:
                - example.com
              methods:
                - GET
                - POST
              headers:
                - Authorization
              exposed_headers:
                - X-My-Header
              max_age: 3600
              credentials: true
          - name: basic-auth
            config:
              hide_credentials: false
consumers:
  - username: example-user
    custom_id: "1234567890"
    basicauth_credentials:
      - username: my_basic_user
        password: my_basic_password
        tags:
          - internal
    plugins:
      - name: rate-limiting-advanced
        config:
          limit:
            - 5
          window_size:
            - 30
          identifier: consumer
          sync_rate: -1
          namespace: example_namespace
          strategy: local
          hide_client_headers: false
consumer_groups:
  - name: example-consumer-group
    consumers:
      - username: example-user
    plugins:
      - name: rate-limiting-advanced
        config:
          limit:
            - 5
          window_size:
            - 30
          identifier: consumer
          sync_rate: -1
          namespace: example_namespace
          strategy: local
          hide_client_headers: false
          window_type: sliding
          retry_after_jitter_max:
            - 0
```

{% endnavtab %}
{% navtab "Converted to Gateway API "%}

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  annotations:
    konghq.com/https-redirect-status-code: "302"
    konghq.com/preserve-host: "true"
    konghq.com/regex-priority: "1"
    konghq.com/snis: example.com
    konghq.com/strip-path: "false"
  name: example-service-example-route
spec:
  hostnames:
    - example.com
    - another-example.com
    - yet-another-example.com
  parentRefs:
    - name: kong
  rules:
    - backendRefs:
        - name: example-service
          port: 80
      filters:
        - extensionRef:
            group: configuration.konghq.com
            kind: KongPlugin
            name: example-service-example-route-cors
          type: ExtensionRef
        - extensionRef:
            group: configuration.konghq.com
            kind: KongPlugin
            name: example-service-example-route-basic-auth
          type: ExtensionRef
      matches:
        - headers:
            - name: x-another-header
              type: Exact
              value: first-header-value,second-header-value
            - name: x-my-header
              type: RegularExpression
              value: foos?bar$
          method: GET
          path:
            type: RegularExpression
            value: /v1/example/?$
    - backendRefs:
        - name: example-service
          port: 80
      filters:
        - extensionRef:
            group: configuration.konghq.com
            kind: KongPlugin
            name: example-service-example-route-cors
          type: ExtensionRef
        - extensionRef:
            group: configuration.konghq.com
            kind: KongPlugin
            name: example-service-example-route-basic-auth
          type: ExtensionRef
      matches:
        - headers:
            - name: x-another-header
              type: Exact
              value: first-header-value,second-header-value
            - name: x-my-header
              type: RegularExpression
              value: foos?bar$
          method: POST
          path:
            type: RegularExpression
            value: /v1/example/?$
    - backendRefs:
        - name: example-service
          port: 80
      filters:
        - extensionRef:
            group: configuration.konghq.com
            kind: KongPlugin
            name: example-service-example-route-cors
          type: ExtensionRef
        - extensionRef:
            group: configuration.konghq.com
            kind: KongPlugin
            name: example-service-example-route-basic-auth
          type: ExtensionRef
      matches:
        - headers:
            - name: x-another-header
              type: Exact
              value: first-header-value,second-header-value
            - name: x-my-header
              type: RegularExpression
              value: foos?bar$
          method: GET
          path:
            type: PathPrefix
            value: /v1/another-example
    - backendRefs:
        - name: example-service
          port: 80
      filters:
        - extensionRef:
            group: configuration.konghq.com
            kind: KongPlugin
            name: example-service-example-route-cors
          type: ExtensionRef
        - extensionRef:
            group: configuration.konghq.com
            kind: KongPlugin
            name: example-service-example-route-basic-auth
          type: ExtensionRef
      matches:
        - headers:
            - name: x-another-header
              type: Exact
              value: first-header-value,second-header-value
            - name: x-my-header
              type: RegularExpression
              value: foos?bar$
          method: POST
          path:
            type: PathPrefix
            value: /v1/another-example
    - backendRefs:
        - name: example-service
          port: 80
      filters:
        - extensionRef:
            group: configuration.konghq.com
            kind: KongPlugin
            name: example-service-example-route-cors
          type: ExtensionRef
        - extensionRef:
            group: configuration.konghq.com
            kind: KongPlugin
            name: example-service-example-route-basic-auth
          type: ExtensionRef
      matches:
        - headers:
            - name: x-another-header
              type: Exact
              value: first-header-value,second-header-value
            - name: x-my-header
              type: RegularExpression
              value: foos?bar$
          method: GET
          path:
            type: PathPrefix
            value: /v1/yet-another-example
    - backendRefs:
        - name: example-service
          port: 80
      filters:
        - extensionRef:
            group: configuration.konghq.com
            kind: KongPlugin
            name: example-service-example-route-cors
          type: ExtensionRef
        - extensionRef:
            group: configuration.konghq.com
            kind: KongPlugin
            name: example-service-example-route-basic-auth
          type: ExtensionRef
      matches:
        - headers:
            - name: x-another-header
              type: Exact
              value: first-header-value,second-header-value
            - name: x-my-header
              type: RegularExpression
              value: foos?bar$
          method: POST
          path:
            type: PathPrefix
            value: /v1/yet-another-example
---
apiVersion: configuration.konghq.com/v1
config:
  hide_client_headers: false
  identifier: consumer
  limit:
    - 5
  namespace: example_namespace
  strategy: local
  sync_rate: -1
  window_size:
    - 30
kind: KongPlugin
metadata:
  annotations:
    kubernetes.io/ingress.class: kong
  name: example-service-rate-limiting-advanced
plugin: rate-limiting-advanced
---
apiVersion: configuration.konghq.com/v1
config:
  credentials: true
  exposed_headers:
    - X-My-Header
  headers:
    - Authorization
  max_age: 3600
  methods:
    - GET
    - POST
  origins:
    - example.com
kind: KongPlugin
metadata:
  annotations:
    kubernetes.io/ingress.class: kong
  name: example-service-example-route-cors
plugin: cors
---
apiVersion: configuration.konghq.com/v1
config:
  hide_credentials: false
kind: KongPlugin
metadata:
  annotations:
    kubernetes.io/ingress.class: kong
  name: example-service-example-route-basic-auth
plugin: basic-auth
---
apiVersion: configuration.konghq.com/v1
config:
  hide_client_headers: false
  identifier: consumer
  limit:
    - 5
  namespace: example_namespace
  strategy: local
  sync_rate: -1
  window_size:
    - 30
kind: KongPlugin
metadata:
  annotations:
    kubernetes.io/ingress.class: kong
  name: example-user-rate-limiting-advanced
plugin: rate-limiting-advanced
---
apiVersion: v1
kind: Service
metadata:
  annotations:
    konghq.com/connect-timeout: "5000"
    konghq.com/path: /v1
    konghq.com/plugins: example-service-rate-limiting-advanced
    konghq.com/protocol: http
    konghq.com/read-timeout: "60000"
    konghq.com/retries: "5"
    konghq.com/write-timeout: "60000"
  name: example-service
spec:
  ports:
    - port: 80
      protocol: TCP
      targetPort: 80
  selector:
    app: example-service
---
apiVersion: v1
kind: Secret
metadata:
  annotations:
    kubernetes.io/ingress.class: kong
  labels:
    konghq.com/credential: basic-auth
  name: basic-auth-example-user
stringData:
  password: my_basic_password
  username: my_basic_user
---
apiVersion: configuration.konghq.com/v1
consumerGroups:
  - example-consumer-group
credentials:
  - basic-auth-example-user
custom_id: "1234567890"
kind: KongConsumer
metadata:
  annotations:
    konghq.com/plugins: example-user-rate-limiting-advanced
    kubernetes.io/ingress.class: kong
  name: example-user
username: example-user
---
apiVersion: configuration.konghq.com/v1beta1
kind: KongConsumerGroup
metadata:
  annotations:
    kubernetes.io/ingress.class: kong
  name: example-consumer-group
---
```

{% endnavtab %}
{% navtab "Converted to Ingress API "%}

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    konghq.com/headers.x-another-header: first-header-value,second-header-value
    konghq.com/headers.x-my-header: ~*foos?bar$
    konghq.com/https-redirect-status-code: "302"
    konghq.com/methods: GET,POST
    konghq.com/plugins: example-service-example-route-cors,example-service-example-route-basic-auth
    konghq.com/preserve-host: "true"
    konghq.com/protocols: http,https
    konghq.com/regex-priority: "1"
    konghq.com/snis: example.com
    konghq.com/strip-path: "false"
  name: example-service-example-route
spec:
  ingressClassName: kong
  rules:
    - host: example.com
      http:
        paths:
          - backend:
              service:
                name: example-service
                port:
                  number: 80
            path: /~/v1/example/?$
            pathType: ImplementationSpecific
          - backend:
              service:
                name: example-service
                port:
                  number: 80
            path: /v1/another-example
            pathType: ImplementationSpecific
          - backend:
              service:
                name: example-service
                port:
                  number: 80
            path: /v1/yet-another-example
            pathType: ImplementationSpecific
    - host: another-example.com
      http:
        paths:
          - backend:
              service:
                name: example-service
                port:
                  number: 80
            path: /~/v1/example/?$
            pathType: ImplementationSpecific
          - backend:
              service:
                name: example-service
                port:
                  number: 80
            path: /v1/another-example
            pathType: ImplementationSpecific
          - backend:
              service:
                name: example-service
                port:
                  number: 80
            path: /v1/yet-another-example
            pathType: ImplementationSpecific
    - host: yet-another-example.com
      http:
        paths:
          - backend:
              service:
                name: example-service
                port:
                  number: 80
            path: /~/v1/example/?$
            pathType: ImplementationSpecific
          - backend:
              service:
                name: example-service
                port:
                  number: 80
            path: /v1/another-example
            pathType: ImplementationSpecific
          - backend:
              service:
                name: example-service
                port:
                  number: 80
            path: /v1/yet-another-example
            pathType: ImplementationSpecific
---
apiVersion: configuration.konghq.com/v1
config:
  hide_client_headers: false
  identifier: consumer
  limit:
    - 5
  namespace: example_namespace
  strategy: local
  sync_rate: -1
  window_size:
    - 30
kind: KongPlugin
metadata:
  annotations:
    kubernetes.io/ingress.class: kong
  name: example-service-rate-limiting-advanced
plugin: rate-limiting-advanced
---
apiVersion: configuration.konghq.com/v1
config:
  credentials: true
  exposed_headers:
    - X-My-Header
  headers:
    - Authorization
  max_age: 3600
  methods:
    - GET
    - POST
  origins:
    - example.com
kind: KongPlugin
metadata:
  annotations:
    kubernetes.io/ingress.class: kong
  name: example-service-example-route-cors
plugin: cors
---
apiVersion: configuration.konghq.com/v1
config:
  hide_credentials: false
kind: KongPlugin
metadata:
  annotations:
    kubernetes.io/ingress.class: kong
  name: example-service-example-route-basic-auth
plugin: basic-auth
---
apiVersion: configuration.konghq.com/v1
config:
  hide_client_headers: false
  identifier: consumer
  limit:
    - 5
  namespace: example_namespace
  strategy: local
  sync_rate: -1
  window_size:
    - 30
kind: KongPlugin
metadata:
  annotations:
    kubernetes.io/ingress.class: kong
  name: example-user-rate-limiting-advanced
plugin: rate-limiting-advanced
---
apiVersion: v1
kind: Service
metadata:
  annotations:
    konghq.com/connect-timeout: "5000"
    konghq.com/path: /v1
    konghq.com/plugins: example-service-rate-limiting-advanced
    konghq.com/protocol: http
    konghq.com/read-timeout: "60000"
    konghq.com/retries: "5"
    konghq.com/write-timeout: "60000"
  name: example-service
spec:
  ports:
    - port: 80
      protocol: TCP
      targetPort: 80
  selector:
    app: example-service
---
apiVersion: v1
kind: Secret
metadata:
  annotations:
    kubernetes.io/ingress.class: kong
  labels:
    konghq.com/credential: basic-auth
  name: basic-auth-example-user
stringData:
  password: my_basic_password
  username: my_basic_user
---
apiVersion: configuration.konghq.com/v1
consumerGroups:
  - example-consumer-group
credentials:
  - basic-auth-example-user
custom_id: "1234567890"
kind: KongConsumer
metadata:
  annotations:
    konghq.com/plugins: example-user-rate-limiting-advanced
    kubernetes.io/ingress.class: kong
  name: example-user
username: example-user
---
apiVersion: configuration.konghq.com/v1beta1
kind: KongConsumerGroup
metadata:
  annotations:
    kubernetes.io/ingress.class: kong
  name: example-consumer-group
---
```

{% endnavtab %}
{% endnavtabs %}
