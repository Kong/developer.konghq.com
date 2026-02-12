---
title: Degraphql
description: |
  Configure the DeGraphQL plugin for {{ site.kic_product_name }} using KongCustomEntity.
content_type: how_to

permalink: /kubernetes-ingress-controller/degraphql/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: How To
plugins:
  - degraphql

products:
  - kic

tools:
  - kic

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: How do I configure the DeGraphQL plugin using {{ site.kic_product_name }}?
  a: |
    Create a `KongCustomEntity` resource that specifies the entity name in `spec.type` and any required properties under `spec.fields`.

prereqs:
  enterprise: true
  kubernetes:
    gateway_api: true

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg
      
related_resources:
    - text: DeGraphQL Plugin
      url: /plugins/degraphql/
---

## Create a GraphQL Service

The `degraphql` plugin requires an upstream GraphQL API. For this how-to, we'll use [Hasura](https://hasura.io/) to create an example GraphQL service:

```bash
echo 'apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: hasura
    hasuraService: custom
  name: hasura
  namespace: kong
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hasura
  template:
    metadata:
      labels:
        app: hasura
    spec:
      containers:
      - image: hasura/graphql-engine:v2.38.0
        imagePullPolicy: IfNotPresent
        name: hasura
        env:
        - name: HASURA_GRAPHQL_DATABASE_URL
          value: postgres://user:password@localhost:5432/hasura_data
        - name: HASURA_GRAPHQL_ENABLE_CONSOLE
          value: "true"
        - name: HASURA_GRAPHQL_DEV_MODE
          value: "true"
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
        resources: {}
      - image: postgres:15
        name: postgres
        env:
        - name: POSTGRES_USER
          value: "user"
        - name: POSTGRES_PASSWORD
          value: "password"
        - name: POSTGRES_DB
          value: "hasura_data"
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: hasura
  name: hasura
  namespace: kong
spec:
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  selector:
    app: hasura
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hasura-ingress-console
  namespace: kong
  annotations:
    konghq.com/strip-path: "true"
spec:
  ingressClassName: kong
  rules:
  - http:
      paths:
      - path: /hasura
        pathType: Prefix
        backend:
          service:
            name: hasura
            port:
              number: 80' | kubectl apply -f -
```

Once the Hasura Pod is running, bootstrap an API to return contact details using the Hasura API:

```bash
curl -X POST -H "Content-Type:application/json" -H "X-Hasura-Role:admin" http://${PROXY_IP}/hasura/v2/query -d '{"type": "run_sql","args": {"sql": "CREATE TABLE contacts(id serial NOT NULL, name text NOT NULL, phone text NOT NULL, PRIMARY KEY(id));"}}'
curl -X POST -H "Content-Type:application/json" -H "X-Hasura-Role:admin" http://${PROXY_IP}/hasura/v2/query -d $'{"type": "run_sql","args": {"sql": "INSERT INTO contacts (name, phone) VALUES (\'Alice\',\'0123456789\');"}}'
curl -X POST -H "Content-Type:application/json" -H "X-Hasura-Role:admin" http://${PROXY_IP}/hasura/v1/metadata -d '{"type": "pg_track_table","args": {"schema": "public","name": "contacts"}}'
```

## Create a Route

Our Hasura API will be exposed using the `/contacts` path. Create an `HTTPRoute` or `Ingress` resource pointing to the `hasura` Service that we can attach the `degraphql` plugin to:

<!--vale off-->
{% httproute %}
name: demo-graphql
matches:
  - path: /contacts
    service: hasura
    port: 80
skip_host: true
{% endhttproute %}
<!--vale on-->
## Configure the DeGraphQL plugin

The `degraphql` plugin accepts a single configuration option, `graphql_server_path`. Create a `KongPlugin` resource and attach it to the `demo-graphql` route that you just created:

{% entity_example %}
type: plugin
data:
  name: degraphql-example
  plugin: degraphql
  config:
    graphql_server_path: /v1/graphql

  route: demo-graphql
{% endentity_example %}

The `degraphql` entity requires you to configure a mapping between paths and GraphQL queries. In this example, we'll map the `/list` path to `query{ contacts { name } }` using the `KongCustomEntity` CRD. The `KongCustomEntity` CRD attaches the `fields` to the `KongPlugin` specified in the `parentRef` field.

The following resource tells {{ site.kic_product_name }} to create a `degraphql_routes` entity in {{ site.base_gateway }} and attach it to the plugin created by the `degraphql-example` `KongPlugin` resource:

```yaml
echo 'apiVersion: configuration.konghq.com/v1alpha1
kind: KongCustomEntity
metadata:
  namespace: kong
  name: degraphql-route-example
spec:
  type: degraphql_routes
  fields:
    uri: "/list"
    query: "query{ contacts { name } }"
  controllerName: kong
  parentRef:
    group: "configuration.konghq.com"
    kind: "KongPlugin"
    name: "degraphql-example"
' | kubectl apply -f -
```

## Test the Service with the DeGraphQL plugin

To test the `degraphql` plugin, call the `/contacts/list` endpoint. The `/contacts` prefix comes from our Route definition, and the `/list` segment comes from our `degraphql_routes` definition.

{% validation request-check %}
url: /contacts/list
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

The cURL command should return the data that we inserted at the beginning of this how-to:

```json
{"data":{"contacts":[{"name":"Alice"}]}}
```
{:.no-copy-code}