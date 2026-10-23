{%- assign kubectl_context = '' -%}{%- if include.kube_context %}{% assign kubectl_context = ' --context ' | append: include.kube_context %}{% endif -%}
{% unless include.additional_zone %}
Deploy an nginx `server` and a `curl` `client` into a namespace that joins the mesh. The client's
own ServiceAccount gives it the identity that the traffic permission allows. The client also lists
`server` as a reachable backend, because a proxy can only call the destinations it declares. For
more information, see [MeshService](/mesh/meshservice/).
{% endunless %}

1. Create the namespace, the client ServiceAccount, and the server and client workloads:

   ```sh
   cat <<'EOF' | kubectl{{ kubectl_context }} apply -f -
   apiVersion: v1
   kind: Namespace
   metadata:
     name: kong-mesh-demo
     labels:
       kuma.io/mesh: konnect-demo
       kuma.io/sidecar-injection: enabled
   ---
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: client
     namespace: kong-mesh-demo
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: server
     namespace: kong-mesh-demo
   spec:
     selector:
       app: server
     ports:
       - port: 80
         targetPort: 80
         appProtocol: http
   ---
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: server
     namespace: kong-mesh-demo
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: server
     template:
       metadata:
         labels:
           app: server
       spec:
         containers:
           - name: server
             image: nginx:1.27.4
             ports:
               - containerPort: 80
   ---
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: client
     namespace: kong-mesh-demo
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: client
     template:
       metadata:
         labels:
           app: client
         annotations:
           kuma.io/reachable-backends: |
             refs:
             - kind: MeshService
               labels:
                 kuma.io/display-name: server
                 k8s.kuma.io/namespace: kong-mesh-demo
       spec:
         serviceAccountName: client
         containers:
           - name: client
             image: curlimages/curl:8.12.1
             command: ["sleep", "86400"]
   EOF
   ```
   {:.collapsible}

1. Wait for the server and client to roll out:

   ```sh
   kubectl{{ kubectl_context }} -n kong-mesh-demo rollout status deployment/server --timeout=180s
   kubectl{{ kubectl_context }} -n kong-mesh-demo rollout status deployment/client --timeout=180s
   ```
