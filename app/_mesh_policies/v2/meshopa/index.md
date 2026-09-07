---
title: Mesh OPA
name: meshopas
products:
    - mesh
description: 'Integrate Open Policy Agent (OPA) to provide access control for your Services.'
content_type: plugin
type: policy
min_version:
  mesh: '2.6'

icon: policy.svg
---
## MeshOPA policy plugin

{{site.mesh_product_name}} integrates the [Open Policy Agent (OPA)](https://www.openpolicyagent.org/) to provide access control for your services.

The agent is included in the data plane proxy sidecar, instead of the more common deployment as a separate sidecar.

When the `MeshOPA` policy is applied, the control plane configures the following:

- The embedded policy agent, with the specified policy
- Envoy, to use [External Authorization](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/http/ext_authz/v3/ext_authz.proto) that points to the embedded policy agent

## TargetRef support matrix

{% navtabs "support-matrix" %}
{% navtab "Sidecar" %}
<!-- vale off -->
{% table %}
columns:
  - title: "`targetRef`"
    key: targetref
  - title: Allowed kinds
    key: allowed_kinds
rows:
  - targetref: "`targetRef.kind`"
    allowed_kinds: "`Mesh`, `Dataplane` (new_in 2.11), `MeshSubset` (deprecated), `MeshService` (removed in 2.11), `MeshServiceSubset` (removed in 2.11)"
{% endtable %}
<!-- vale on -->
{% endnavtab %}
{% navtab "Built-in Gateway" %}
<!-- vale off -->
{% table %}
columns:
  - title: "`targetRef`"
    key: targetref
  - title: Allowed kinds
    key: allowed_kinds
rows:
  - targetref: "`targetRef.kind`"
    allowed_kinds: "`Mesh`, `MeshGateway`"
{% endtable %}
<!-- vale on -->
{% endnavtab %}
{% endnavtabs %}

## Configuration

To apply a policy with MeshOPA, you must do the following:

- Specify the group of data plane proxies to apply the policy to with the `targetRef` property.
- Provide a policy with the `appendPolicies` property. Policies are defined in the [Rego language](https://www.openpolicyagent.org/docs/latest/policy-language/).
- Optionally provide custom configuration for the policy agent.

### Inline

{% navtabs "inline" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshOPA
metadata:
  name: mopa-1
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default # optional, defaults to `default` if unset
spec:
  targetRef:
    kind: Mesh
  default:
    agentConfig: # optional
      inlineString: | # one of: inlineString, secret
        decision_logs:
          console: true
    appendPolicies:
      - ignoreDecision: false # optional, defaults to 'false'
        rego:
          inlineString: | # one of: inlineString, secret
            package envoy.authz

            import input.attributes.request.http as http_request

            default allow = false

            token = {"valid": valid, "payload": payload} {
                [_, encoded] := split(http_request.headers.authorization, " ")
                [valid, _, payload] := io.jwt.decode_verify(encoded, {"secret": "secret"})
            }

            allow {
                is_token_valid
                action_allowed
            }

            is_token_valid {
              token.valid
              now := time.now_ns() / 1000000000
              token.payload.nbf <= now
              now < token.payload.exp
            }

            action_allowed {
              http_request.method == "GET"
              token.payload.role == "admin"
            }
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: MeshOPA
mesh: default
name: mopa-1
spec:
  targetRef:
    kind: Mesh
  default:
    agentConfig: # optional
      inlineString: | # one of: inlineString, secret
        decision_logs:
          console: true
    appendPolicies: # optional
      - ignoreDecision: false # optional, defaults to 'false'
        rego:
          inlineString: | # one of: inlineString, secret
            package envoy.authz

            import input.attributes.request.http as http_request

            default allow = false

            token = {"valid": valid, "payload": payload} {
                [_, encoded] := split(http_request.headers.authorization, " ")
                [valid, _, payload] := io.jwt.decode_verify(encoded, {"secret": "secret"})
            }

            allow {
                is_token_valid
                action_allowed
            }

            is_token_valid {
              token.valid
              now := time.now_ns() / 1000000000
              token.payload.nbf <= now
              now < token.payload.exp
            }

            action_allowed {
              http_request.method == "GET"
              token.payload.role == "admin"
            }
```

{% endnavtab %}
{% endnavtabs %}

### With secrets

Encoding the policy in a Secret provides some security for policies that contain sensitive data.

{% navtabs "with secrets" %}
{% navtab "Kubernetes" %}

1.  Define a Secret with a policy that's Base64-encoded:

    ```yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: mopa-policy
      namespace: kong-mesh-system
      labels:
        kuma.io/mesh: default
    data:
      value: cGFja2FnZSBlbnZveS5hdXRoegoKaW1wb3J0IGlucHV0LmF0dHJpYnV0ZXMucmVxdWVzdC5odHRwIGFzIGh0dHBfcmVxdWVzdAoKZGVmYXVsdCBhbGxvdyA9IGZhbHNlCgp0b2tlbiA9IHsidmFsaWQiOiB2YWxpZCwgInBheWxvYWQiOiBwYXlsb2FkfSB7CiAgICBbXywgZW5jb2RlZF0gOj0gc3BsaXQoaHR0cF9yZXF1ZXN0LmhlYWRlcnMuYXV0aG9yaXphdGlvbiwgIiAiKQogICAgW3ZhbGlkLCBfLCBwYXlsb2FkXSA6PSBpby5qd3QuZGVjb2RlX3ZlcmlmeShlbmNvZGVkLCB7InNlY3JldCI6ICJzZWNyZXQifSkKfQoKYWxsb3cgewogICAgaXNfdG9rZW5fdmFsaWQKICAgIGFjdGlvbl9hbGxvd2VkCn0KCmlzX3Rva2VuX3ZhbGlkIHsKICB0b2tlbi52YWxpZAogIG5vdyA6PSB0aW1lLm5vd19ucygpIC8gMTAwMDAwMDAwMAogIHRva2VuLnBheWxvYWQubmJmIDw9IG5vdwogIG5vdyA8IHRva2VuLnBheWxvYWQuZXhwCn0KCmFjdGlvbl9hbGxvd2VkIHsKICBodHRwX3JlcXVlc3QubWV0aG9kID09ICJHRVQiCiAgdG9rZW4ucGF5bG9hZC5yb2xlID09ICJhZG1pbiIKfQoK
    type: system.kuma.io/secret
    ```

1.  Pass the Secret to `MeshOPA`:

    ```yaml
    apiVersion: kuma.io/v1alpha1
    kind: MeshOPA
    metadata:
      name: mopa-1
      namespace: kong-mesh-system
      labels:
        kuma.io/mesh: default
    spec:
      targetRef:
        kind: Mesh
      default:
        appendPolicies:
          - rego:
              secret: mopa-policy
    ```

{% endnavtab %}
{% navtab "Universal" %}

1.  Define a Secret with a policy that's Base64-encoded:

    ```yaml
    type: Secret
    name: sample-secret
    mesh: default
    data: cGFja2FnZSBlbnZveS5hdXRoegoKaW1wb3J0IGlucHV0LmF0dHJpYnV0ZXMucmVxdWVzdC5odHRwIGFzIGh0dHBfcmVxdWVzdAoKZGVmYXVsdCBhbGxvdyA9IGZhbHNlCgp0b2tlbiA9IHsidmFsaWQiOiB2YWxpZCwgInBheWxvYWQiOiBwYXlsb2FkfSB7CiAgICBbXywgZW5jb2RlZF0gOj0gc3BsaXQoaHR0cF9yZXF1ZXN0LmhlYWRlcnMuYXV0aG9yaXphdGlvbiwgIiAiKQogICAgW3ZhbGlkLCBfLCBwYXlsb2FkXSA6PSBpby5qd3QuZGVjb2RlX3ZlcmlmeShlbmNvZGVkLCB7InNlY3JldCI6ICJzZWNyZXQifSkKfQoKYWxsb3cgewogICAgaXNfdG9rZW5fdmFsaWQKICAgIGFjdGlvbl9hbGxvd2VkCn0KCmlzX3Rva2VuX3ZhbGlkIHsKICB0b2tlbi52YWxpZAogIG5vdyA6PSB0aW1lLm5vd19ucygpIC8gMTAwMDAwMDAwMAogIHRva2VuLnBheWxvYWQubmJmIDw9IG5vdwogIG5vdyA8IHRva2VuLnBheWxvYWQuZXhwCn0KCmFjdGlvbl9hbGxvd2VkIHsKICBodHRwX3JlcXVlc3QubWV0aG9kID09ICJHRVQiCiAgdG9rZW4ucGF5bG9hZC5yb2xlID09ICJhZG1pbiIKfQoK
    ```

1.  Pass the Secret to `MeshOPA`:

    ```yaml
    type: MeshOPA
    mesh: default
    name: mopa-1
    spec:
      targetRef:
        kind: Mesh
      default:
        appendPolicies:
          - rego:
              secret: mopa-policy
    ```

{% endnavtab %}
{% endnavtabs %}

## Configuration

{{site.mesh_product_name}} defines a default configuration for OPA, but you can adjust the configuration to meet your environment's requirements.

The following environment variables are available:

<!-- vale off -->
{% table %}
columns:
  - title: Variable
    key: variable
  - title: Type
    key: type
  - title: What it configures
    key: what_it_configures
  - title: Default value
    key: default_value
rows:
  - variable: KMESH_OPA_ADDR
    type: string
    what_it_configures: Address OPA API server listens on
    default_value: "`localhost:8181`"
  - variable: KMESH_OPA_CONFIG_PATH
    type: string
    what_it_configures: Path to file of initial config
    default_value: N/A
  - variable: KMESH_OPA_DIAGNOSTIC_ADDR
    type: string
    what_it_configures: Address of OPA diagnostics server
    default_value: "`0.0.0.0:8282`"
  - variable: KMESH_OPA_ENABLED
    type: bool
    what_it_configures: "Whether `kuma-dp` starts embedded OPA"
    default_value: "true"
  - variable: KMESH_OPA_EXT_AUTHZ_ADDR
    type: string
    what_it_configures: Address of Envoy External AuthZ service
    default_value: "`localhost:9191`"
  - variable: KMESH_OPA_CONFIG_OVERRIDES
    type: strings
    what_it_configures: "Overrides for OPA configuration, in addition to config file(*)"
    default_value: nil
{% endtable %}
<!-- vale on -->

{% navtabs  "configuration" %}
{% navtab "kumactl" %}

When you deploy the Mesh control plane, edit the `kong-mesh-control-plane-config` ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kong-mesh-control-plane-config
  namespace: kong-mesh-system
data:
  config.yaml: |
    runtime:
      kubernetes:
        injector:
          sidecarContainer:
            envVars:
              KMESH_OPA_ENABLED: "false"
              KMESH_OPA_ADDR: ":8888"
              KMESH_OPA_CONFIG_OVERRIDES: "config1:x,config2:y"
```

{% endnavtab %}
{% navtab "Helm" %}

Override the Helm value in `values.yaml`

```yaml
kuma:
  controlPlane:
    config: |
      runtime:
        kubernetes:
          injector:
            sidecarContainer:
              envVars:
                KMESH_OPA_ENABLED: "false"
                KMESH_OPA_ADDR: ":8888"
                KMESH_OPA_CONFIG_OVERRIDES: "config1:x,config2:y"
```

{% endnavtab %}
{% navtab "Pod" %}

Override the config for individual data plane proxies by placing the appropriate annotations on the Pod:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-app
  namespace: kong-mesh-example
spec:
  ...
  template:
    metadata:
      ...
      annotations:
        # indicate to {{site.mesh_product_name}} that this Pod doesn't need a sidecar
        kuma.io/sidecar-env-vars: "KMESH_OPA_ENABLED=false;KMESH_OPA_ADDR=:8888;KMESH_OPA_CONFIG_OVERRIDES=config1:x,config2:y"
```
{% endnavtab %}
{% navtab "Universal" %}

The `run` command on the data plane proxy accepts the following equivalent parameters if you prefer not to set environment variables:

```
--opa-addr
--opa-config-path
--opa-diagnostic-addr
--opa-enabled                    
--opa-ext-authz-addr
--opa-set strings
```

{% endnavtab %}
{% endnavtabs %}

## Configuring the authorization filter

You can configure the external authorization filter by adjusting the `authConfig` section.

{% navtabs "auth-filter" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshOPA
metadata:
  name: mopa-1
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default # optional, defaults to `default` if unset
spec:
  targetRef:
    kind: Mesh
  default:
    authConfig: # optional
      statusOnError: 413 # optional: defaults to 403.
      onAgentFailure: Allow # optional: one of 'Allow' or 'Deny', defaults to 'Deny' defines the behavior when communication with the agent fails or the policy execution fails.
      requestBody: # optional
          maxSize: 1024 # the max number of bytes to send to the agent, if we exceed this, the request to the agent will have: `x-envoy-auth-partial-body: true`.
          sendRawBody: true # use when the body is not plaintext. The agent request will have `raw_body` instead of `body`
...
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: MeshOPA
mesh: default
name: mopa-1
spec:
  targetRef:
    kind: Mesh
  default:
    authConfig: # optional
      statusOnError: 413 # optional: defaults to 403. http statusCode to use when the connection to the agent failed.
      onAgentFailure: Allow # optional: one of 'Allow' or 'Deny', defaults to 'deny'. defines the behavior when communication with the agent fails or the policy execution fails.
      requestBody: # optional
        maxSize: 1024 # the maximum number of bytes to send to the agent, if we exceed this, the request to the agent will have: `x-envoy-auth-partial-body: true`.
        sendRawBody: true # use when the body is not plaintext. The agent request will have `raw_body` instead of `body`
...
```

{% endnavtab %}
{% endnavtabs %}

By default, the body is not sent to the agent.
To send it, set `authConfig.requestBody.maxSize` to the maximum size of your body.
If the request body is larger than this parameter, it is truncated and the header `x-envoy-auth-partial-body` is set to `true`.

## Support for external API management servers

The `agentConfig` field lets you define a custom configuration that points to an external management server:

{% navtabs "external-api-management" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshOPA
metadata:
  name: mopa-1
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    agentConfig:
      inlineString: |
        services:
          acmecorp:
            url: https://example.com/control-plane-api/v1
            credentials:
              bearer:
                token: "bGFza2RqZmxha3NkamZsa2Fqc2Rsa2ZqYWtsc2RqZmtramRmYWxkc2tm"

        discovery:
          name: example
          resource: /configuration/example/discovery
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: MeshOPA
mesh: default
name: mopa-1
spec:
  targetRef:
    kind: Mesh
  default:
    agentConfig:
      inlineString: | # one of: inlineString, secret
        services:
          acmecorp:
            url: https://example.com/control-plane-api/v1
            credentials:
              bearer:
                token: "bGFza2RqZmxha3NkamZsa2Fqc2Rsa2ZqYWtsc2RqZmtramRmYWxkc2tm"
        discovery:
          name: example
          resource: /configuration/example/discovery
```

{% endnavtab %}
{% endnavtabs %}

## Composing policies

In your organization, the mesh operator may want to set a policy for subset of proxies in the mesh.
At the same time, service owners may want to exercise additional policies.

For example, the mesh operator may want to enable JWT token validation for all proxies in the mesh
```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshOPA
metadata:
  name: mopa-mesh-operator
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
  default:
    appendPolicies:
      - rego:
          inlineString: |
            package operator
            
            import input.attributes.request.http as http_request
            
            default allow = false
            
            token = {"valid": valid, "payload": payload} {
                [_, encoded] := split(http_request.headers.authorization, " ")
                [valid, _, payload] := io.jwt.decode_verify(encoded, {"secret": "secret"})
            }
            
            allow {
                is_token_valid
                action_allowed
            }
            
            is_token_valid {
              token.valid
              now := time.now_ns() / 1000000000
              token.payload.nbf <= now
              now < token.payload.exp
            }
            
            action_allowed {
              http_request.method == "GET"
              token.payload.role == "admin"
            }
```

Service owner wants to block all requests on path `/blocked`:

```yaml
apiVersion: kuma.io/v1alpha1
kind: MeshOPA
metadata:
  name: mopa-service-owner
  namespace: kong-mesh-system
  labels:
    kuma.io/mesh: default
spec:
  targetRef:
    kind: Mesh
    labels:
      kuma.io/service: test-server_kuma-demo_svc_80
  default:
    appendPolicies:
      - rego:
          inlineString: |
            package serviceowner
            
            default allow = true
            
            deny {
              input.parsed_path == ["blocked"]
            }
```

`appendPolicies` is a list you can append, therefore in the case of the data plane proxy `test-server_kuma-demo_svc_80` service, both policies are applied.

{{site.mesh_product_name}} will autogenerate an additional OPA decision policy:
```rego
package implicitkmesh
import data.operator
import data.serviceowner

allow {
  data.operator.allow
  not data.operator.deny
  data.serviceowner.allow
  not data.serviceowner.deny
}
```
It also configures the OPA agent decision path (`plugins.envoy_ext_authz_grpc.path`) to `implicitkmesh/allow`.

You can also add a rego policy which is not part of the decision.
Set a `appendPolicies[*].ignoreDecision` to true so the rego policy won't be added to autogenerated decision policy.
This way, the mesh operator can expose utility functions to service owner.

## Example

The following example shows how to deploy and test a sample MeshOPA policy on Kubernetes, using the kong-mesh-demo application.

1.  Deploy the example application:

    ```sh
    echo "apiVersion: v1
    kind: Namespace
    metadata:
      name: kong-mesh-demo
      labels:
        kuma.io/sidecar-injection: enabled
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: postgres-master
      namespace: kong-mesh-demo
      labels:
        app: postgres
    spec:
      selector:
        matchLabels:
          app: postgres
      replicas: 1
      template:
        metadata:
          labels:
            app: postgres
        spec:
          containers:
          - name: master
            image: kvn0218/postgres:latest
            env:
            - name: POSTGRES_USER
              value: kumademo
            - name: POSTGRES_PASSWORD
              value: kumademo
            - name: POSTGRES_DB
              value: kumademo
            - name: PGDATA
              value: /var/lib/postgresql/data/pgdata
            resources:
              requests:
                cpu: 100m
                memory: 128Mi
              limits:
                cpu: 150m
                memory: 256Mi
            ports:
            - containerPort: 5432
            volumeMounts:
            - mountPath: /var/lib/postgresql/data
              name: pgdata
          volumes:
          - emptyDir: {}
            name: pgdata
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: postgres
      namespace: kong-mesh-demo
      labels:
        app: postgres
    spec:
      ports:
      - protocol: TCP
        port: 5432
        targetPort: 5432
      selector:
        app: postgres
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: redis-master
      namespace: kong-mesh-demo
      labels:
        app: redis
    spec:
      selector:
        matchLabels:
          app: redis
          role: master
          tier: backend
      replicas: 1
      template:
        metadata:
          labels:
            app: redis
            role: master
            tier: backend
        spec:
          containers:
          - name: master
            image: kvn0218/kuma-redis
            resources:
              requests:
                cpu: 100m
                memory: 128Mi
              limits:
                cpu: 150m
                memory: 256Mi
            ports:
            - containerPort: 6379
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: redis
      namespace: kong-mesh-demo
      labels:
        app: redis
        role: master
        tier: backend
    spec:
      ports:
      - port: 6379
        targetPort: 6379
      selector:
        app: redis
        role: master
        tier: backend
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: backend
      namespace: kong-mesh-demo
      annotations:
        3001.service.kuma.io/protocol: \"http\"
    spec:
      selector:
        app: kong-mesh-demo-backend
      ports:
      - name: api
        port: 3001
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: kong-mesh-demo-backend-v0
      namespace: kong-mesh-demo
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: kong-mesh-demo-backend
          version: v0
          env: prod
      template:
        metadata:
          labels:
            app: kong-mesh-demo-backend
            version: v0
            env: prod
        spec:
          containers:
          - image: kvn0218/kuma-demo-be:latest
            name: kuma-be
            env:
            - name: POSTGRES_HOST
              value: postgres_kong-mesh-demo_svc_5432.mesh
            - name: POSTGRES_PORT_NUM
              value: \"80\"
            - name: SPECIAL_OFFER
              value: \"false\"
            - name: REDIS_HOST
              value: redis_kong-mesh-demo_svc_6379.mesh
            - name: REDIS_PORT
              value: \"80\"
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 3001
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: kong-mesh-demo-backend-v1
      namespace: kong-mesh-demo
    spec:
      replicas: 0
      selector:
        matchLabels:
          app: kong-mesh-demo-backend
          version: v1
          env: intg
      template:
        metadata:
          labels:
            app: kong-mesh-demo-backend
            version: v1
            env: intg
        spec:
          containers:
          - image: kvn0218/kuma-demo-be:latest
            name: kuma-be
            env:
            - name: POSTGRES_HOST
              value: postgres_kong-mesh-demo_svc_5432.mesh
            - name: POSTGRES_PORT_NUM
              value: \"80\"
            - name: REDIS_HOST
              value: redis_kong-mesh-demo_svc_6379.mesh
            - name: REDIS_PORT
              value: \"80\"
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 3001
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: kong-mesh-demo-backend-v2
      namespace: kong-mesh-demo
    spec:
      replicas: 0
      selector:
        matchLabels:
          app: kong-mesh-demo-backend
          version: v2
          env: dev
      template:
        metadata:
          labels:
            app: kong-mesh-demo-backend
            version: v2
            env: dev
        spec:
          containers:
          - image: kvn0218/kuma-demo-be:latest
            name: kuma-be
            env:
            - name: POSTGRES_HOST
              value: postgres_kong-mesh-demo_svc_5432.mesh
            - name: POSTGRES_PORT_NUM
              value: \"80\"
            - name: TOTAL_OFFER
              value: \"2\"
            - name: REDIS_HOST
              value: redis_kong-mesh-demo_svc_6379.mesh
            - name: REDIS_PORT
              value: \"80\"
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 3001
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: frontend
      namespace: kong-mesh-demo
      annotations:
        8080.service.kuma.io/protocol: \"http\"
        ingress.kubernetes.io/service-upstream: \"true\"
    spec:
      selector:
        app: kong-mesh-demo-frontend
      ports:
      - name: http
        port: 8080
        targetPort: 8080
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: kong-mesh-demo-app
      namespace: kong-mesh-demo
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: kong-mesh-demo-frontend
          version: v8
          env: prod
      template:
        metadata:
          labels:
            app: kong-mesh-demo-frontend
            version: v8
            env: prod
        spec:
          containers:
          - name: kong-mesh-fe
            image: kvn0218/kuma-demo-fe:latest
            args: [\"-P\", \"http://backend_kong-mesh-demo_svc_3001.mesh\"]
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 8080" | kubectl apply -f -
    ```
    {:.collapsible}

1.  Make a request from the frontend to the backend:

    ```sh
    kubectl exec -i -t $(kubectl get pod -l "app=kong-mesh-demo-frontend" -o jsonpath='{.items[0].metadata.name}' -n kong-mesh-demo) -n kong-mesh-demo -c kong-mesh-fe -- curl backend:3001 -v
    ```
 
    The output looks like:
 
    ```
    *   Trying 127.0.0.1:3001...
    * TCP_NODELAY set
    * Connected to backend (127.0.0.1) port 3001 (#0)
    > GET / HTTP/1.1
    > Host: backend:3001
    > User-Agent: curl/7.67.0
    > Accept: */*
    > 
    * Mark bundle as not supporting multiuse
    < HTTP/1.1 200 OK
    < x-powered-by: Express
    < cache-control: no-store, no-cache, must-revalidate, private
    < access-control-allow-origin: *
    < access-control-allow-methods: PUT, GET, POST, DELETE, OPTIONS
    < access-control-allow-headers: *
    < host: backend:3001
    < user-agent: curl/7.67.0
    < accept: */*
    < x-forwarded-proto: http
    < x-request-id: cfbb5987-f534-44dc-97f3-e6edbe4b29ae
    < content-type: text/html; charset=utf-8
    < content-length: 90
    < date: Thu, 23 Jul 2026 11:12:36 GMT
    < x-envoy-upstream-service-time: 17
    < server: envoy
    < 
    * Connection #0 to host backend left intact
    Hello World! Marketplace with sales and reviews made with <3 by the OCTO team at Kong Inc.
    ```
    {:.no-copy-code}

1.  Apply a MeshOPA policy that requires a valid JWT token:

    ```sh
    echo "
    apiVersion: kuma.io/v1alpha1
    kind: MeshOPA
    metadata:
      namespace: kong-mesh-system
      name: mopa-1
      labels:
        kuma.io/mesh: default
    spec:
      targetRef:
        kind: Mesh
      default:
        appendPolicies:
          - rego:
              inlineString: |
                package envoy.authz

                import input.attributes.request.http as http_request

                default allow = false

                token = {\"valid\": valid, \"payload\": payload} {
                    [_, encoded] := split(http_request.headers.authorization, \" \")
                    [valid, _, payload] := io.jwt.decode_verify(encoded, {\"secret\": \"secret\"})
                }

                allow {
                    is_token_valid
                    action_allowed
                }

                is_token_valid {
                  token.valid
                  now := time.now_ns() / 1000000000
                  token.payload.nbf <= now
                  now < token.payload.exp
                }

                action_allowed {
                  http_request.method == \"GET\"
                  token.payload.role == \"admin\"
                }
    " | kubectl apply -f -
    ```

1. Make an invalid request from the frontend to the backend:

    ```sh
    kubectl exec -i -t $(kubectl get pod -l "app=kong-mesh-demo-frontend" -o jsonpath='{.items[0].metadata.name}' -n kong-mesh-demo) -n kong-mesh-demo -c kong-mesh-fe -- curl backend:3001 -v
    ```
    The output looks like:
 
    ```
    *   Trying 127.0.0.1:3001...
    * TCP_NODELAY set
    * Connected to backend (127.0.0.1) port 3001 (#0)
    > GET / HTTP/1.1
    > Host: backend:3001
    > User-Agent: curl/7.67.0
    > Accept: */*
    > 
    * Mark bundle as not supporting multiuse
    < HTTP/1.1 403 Forbidden
    < date: Thu, 23 Jul 2026 11:16:12 GMT
    < server: envoy
    < x-envoy-upstream-service-time: 4
    < content-length: 0
    < 
    * Connection #0 to host backend left intact
    ```
    {:.no-copy-code}

    Note the `HTTP/1.1 403 Forbidden` message. The application doesn't allow a request without a valid token.

    The policy can take up to 30 seconds to propagate, so if this request succeeds the first time, wait and then try again.

1.  Make a valid request from the frontend to the backend.

    Export the token into an environment variable:
    ```sh
    export ADMIN_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYWRtaW4iLCJzdWIiOiJZbTlpIiwibmJmIjoxNTE0ODUxMTM5LCJleHAiOjI1MjQ2MDgwMDB9.H0-42LYzoWyQ_4MXAcED30u6lA5JE087eECV2nxDfXo"
    ```

    Make the request:
    ```sh
    kubectl exec -i -t $(kubectl get pod -l "app=kong-mesh-demo-frontend" -o jsonpath='{.items[0].metadata.name}' -n kong-mesh-demo) -n kong-mesh-demo -c kong-mesh-fe -- curl -H "Authorization: Bearer $ADMIN_TOKEN" backend:3001 -v
    ```

    The output looks like:

    ```
    *   Trying 127.0.0.1:3001...
    * TCP_NODELAY set
    * Connected to backend (127.0.0.1) port 3001 (#0)
    > GET / HTTP/1.1
    > Host: backend:3001
    > User-Agent: curl/7.67.0
    > Accept: */*
    > 
    * Mark bundle as not supporting multiuse
    < HTTP/1.1 200 OK
    < x-powered-by: Express
    < cache-control: no-store, no-cache, must-revalidate, private
    < access-control-allow-origin: *
    < access-control-allow-methods: PUT, GET, POST, DELETE, OPTIONS
    < access-control-allow-headers: *
    < host: backend:3001
    < user-agent: curl/7.67.0
    < accept: */*
    < x-forwarded-proto: http
    < x-request-id: eba9d07f-980b-46ff-a926-542c34615703
    < content-type: text/html; charset=utf-8
    < content-length: 90
    < date: Thu, 23 Jul 2026 11:21:48 GMT
    < x-envoy-upstream-service-time: 12
    < server: envoy
    < 
    * Connection #0 to host backend left intact
    Hello World! Marketplace with sales and reviews made with <3 by the OCTO team at Kong Inc.
    ```
    {:.no-copy-code}

   The request is valid again because the token is signed with the `secret` private key, its payload includes the admin role, and it is not expired.
