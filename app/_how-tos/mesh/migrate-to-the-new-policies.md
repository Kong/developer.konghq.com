---
title: 'Migrate to the new policies'
description: 'Migrate from old to new policies in {{site.mesh_product_name}} to improve flexibility and transparency.'

content_type: how_to
permalink: /mesh/migration-to-the-new-policies/
bread-crumbs: 
  - /mesh/
related_resources:
    - text: Mesh policies
      url: '/mesh/policies-introduction/'
    - text: Policy Hub
      url: /mesh/policies/

min_version:
  mesh: '2.7'

products:
  - mesh

tldr:
  q: How can I migrate from an old policy to the corresponding new policy?
  a: |
    1. Create the new policy in [shadow mode](/mesh/policies-introduction/#applying-policies-in-shadow-mode), to avoid traffic disruption.
    1. Inspect the list of changes between the old and new policies.
    1. Remove the `kuma.io/effect: shadow` label from the new policy.
    1. Observe metrics, traces and logs, and delete the old policy if everything looks good. Otherwise, go back to step 2.

prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: Install kumactl
      include_content: prereqs/tools/kumactl
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster

cleanup:
  inline:
    - title: Clean up kumactl control plane
      include_content: cleanup/products/kumactl
    - title: Clean up {{site.mesh_product_name}} resources
      include_content: cleanup/products/mesh

---

## Install {{site.mesh_product_name}}

1. Install {{site.mesh_product_name}} without a mesh:

   ```sh
   helm upgrade \
     --install \
     --create-namespace \
     --namespace kong-mesh-system \
     kong-mesh kong-mesh/kong-mesh \
     --set "kuma.controlPlane.defaults.skipMeshCreation=true"
   
   kubectl wait -n kong-mesh-system --for=condition=ready pod --selector=app=kong-mesh-control-plane --timeout=90s
   ``` 

2. Make sure that the list of meshes is empty:

   ```sh
   kubectl get meshes
   ```

   You should get the following response:

   ```sh
   No resources found
   ```
   {:.no-copy-code}

## Create a mesh

In this example, we'll deploy a demo app in a `default` mesh and add old policies, before migrating to new ones.

Run the following command to create a mesh named `default` with no initial policies:

```sh
echo 'apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  skipCreatingInitialPolicies: ["*"] ' | kubectl apply -f-
```

## Deploy a demo app

1. Run the following command to deploy a demo app:

   ```sh
   echo '
   apiVersion: v1
   kind: Namespace
   metadata:
     name: kong-mesh-demo
     labels:
       kuma.io/sidecar-injection: enabled
   ---
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: redis
     namespace: kong-mesh-demo
   spec:
     selector:
       matchLabels:
         app: redis
     replicas: 1
     template:
       metadata:
         labels:
           app: redis
       spec:
         containers:
           - name: redis
             image: "redis"
             ports:
               - name: tcp
                 containerPort: 6379
             lifecycle:
               preStop: # delay shutdown to support graceful mesh leave
                 exec:
                   command: ["/bin/sleep", "30"]
               postStart:
                 exec:
                   command:
                     - /bin/sh
                     - -c
                     - |
                       # wait until redis responds before setting the key
                       for i in $(seq 1 30); do
                         if /usr/local/bin/redis-cli ping >/dev/null 2>&1; then
                           /usr/local/bin/redis-cli set zone local && exit 0
                         fi
                         sleep 1
                       done
                       echo "Redis not ready after 30s, skipping postStart"
                       exit 0
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: redis
     namespace: kong-mesh-demo
     labels:
       app: redis
   spec:
     selector:
       app: redis
     ports:
     - protocol: TCP
       port: 6379
   ---
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: demo-app
     namespace: kong-mesh-demo
   spec:
     selector:
       matchLabels:
         app: demo-app
     replicas: 1
     template:
       metadata:
         labels:
           app: demo-app
       spec:
         containers:
           - name: demo-app
             image: "kumahq/kuma-demo"
             env:
               - name: REDIS_HOST
                 value: "redis.kong-mesh-demo.svc.cluster.local"
               - name: REDIS_PORT
                 value: "6379"
               - name: APP_VERSION
                 value: "1.0"
               - name: APP_COLOR
                 value: "#efefef"
             ports:
               - name: http
                 containerPort: 5000
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: demo-app
     namespace: kong-mesh-demo
     labels:
       app: demo-app
   spec:
     selector:
       app: demo-app
     ports:
     - protocol: TCP
       appProtocol: http
       port: 5000' | kubectl apply -f -
   
   kubectl wait -n kong-mesh-demo --for=condition=ready pod --selector=app=demo-app --timeout=90s
   ```

1. Port-forward the service to the namespace on port 5000:

   ```sh
   kubectl port-forward svc/demo-app -n kong-mesh-demo 5000:5000
   ```

1. In a browser, go to [http://127.0.0.1:5000/](http://127.0.0.1:5000/) and increment the counter to make sure the service is running correctly.

## Deploy old policies

For this example, we'll create the following old policies:

* `TrafficPermissions`
* `TrafficRoute`
* `Timeout`
* `CircuitBreaker`

In a new terminal, run the following command:

```sh
echo 'apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  skipCreatingInitialPolicies: ["*"]
  mtls:
    enabledBackend: ca-1
    backends:
      - name: ca-1
        type: builtin
---
apiVersion: kuma.io/v1alpha1
kind: TrafficPermission
mesh: default
metadata:
  name: app-to-redis
spec:
  sources:
    - match:
        kuma.io/service: demo-app_kong-mesh-demo_svc_5000
  destinations:
    - match:
        kuma.io/service: redis_kong-mesh-demo_svc_6379
---
apiVersion: kuma.io/v1alpha1
kind: TrafficRoute
mesh: default
metadata:
  name: route-all-default
spec:
  sources:
    - match:
        kuma.io/service: "*"
  destinations:
    - match:
        kuma.io/service: "*"
  conf:
    destination:
      kuma.io/service: "*"
---
apiVersion: kuma.io/v1alpha1
kind: Timeout
mesh: default
metadata:
  name: timeout-global
spec:
  sources:
    - match:
        kuma.io/service: "*"
  destinations:
    - match:
        kuma.io/service: "*"
  conf:
    connectTimeout: 21s
    tcp:
      idleTimeout: 22s
    http:
      idleTimeout: 22s
      requestTimeout: 23s
      streamIdleTimeout: 25s
      maxStreamDuration: 26s
---
apiVersion: kuma.io/v1alpha1
kind: CircuitBreaker
mesh: default
metadata:
  name: cb-global
spec:
  sources:
  - match:
      kuma.io/service: "*"
  destinations:
  - match:
      kuma.io/service: "*"
  conf:
    interval: 21s
    baseEjectionTime: 22s
    maxEjectionPercent: 23
    splitExternalAndLocalErrors: false
    thresholds:
      maxConnections: 24
      maxPendingRequests: 25
      maxRequests: 26
      maxRetries: 27
    detectors:
      totalErrors:
        consecutive: 28
      gatewayErrors:
        consecutive: 29
      localErrors:
        consecutive: 30
      standardDeviation:
        requestVolume: 31
        minimumHosts: 32
        factor: 1.33
      failure:
        requestVolume: 34
        minimumHosts: 35
        threshold: 36' | kubectl apply -f-
```

## Migrate to new policies

Now that we have old policies deployed, we can migrate them to the corresponding new policies. We'll migrate:

* `TrafficPermissions` to [`MeshTrafficPermission`](/mesh/policies/meshtrafficpermission/)
* `Timeout` to [`MeshTimeout`](/mesh/policies/meshtimeout/)
* `CircuitBreaker` to [`MeshCircuitBreaker`](/mesh/policies/meshcircuitbreaker/)

You can migrate all policies at once, but we recommend migrating them separately, since it makes them easier to revert.

The migration process consists or four steps:

1. Create a new policy in [shadow mode](/mesh/policies-introduction/#applying-policies-in-shadow-mode), to avoid traffic disruption.
1. Inspect the list of changes between the old and new policies.
1. Remove the `kuma.io/effect: shadow` label.
1. Observe metrics, traces and logs:
   * If there is an issue, change the policy back to shadow mode and go back to the second step.
   * If everything looks good, remove the old policy.

{:.warning}
> The migration order generally doesn’t matter, except for the `TrafficRoute` policy, which should be the last one deleted when removing old policies. This is because many old policies, like `Timeout` and `CircuitBreaker`, depend on `TrafficRoute` policies to function correctly.

### Set up kumactl

Before we start migrating, we need to set up kumactl, which we'll use to inspect the policies.

1. Run the following command to expose the control plane's API server. We'll need this to access kumactl:

   ```sh
   kubectl --context mesh-zone port-forward svc/kong-mesh-control-plane -n kong-mesh-system 5681:5681
   ```

1. In a new terminal, check that kumactl is installed and that its directory is in your path:

   ```sh
   kumactl
   ```

   If the command is not found:

   1. Make sure that kumactl is [installed](#install-kumactl)
   1. Add the {{site.mesh_product_name}} binaries directory to your path:

      ```sh
      export PATH=$PATH:$(pwd)/{{site.mesh_product_name_path}}-{{site.data.mesh_latest.version}}/bin
      ```

1. Export your admin token and add your control plane:

   ```sh
   export ZONE_USER_ADMIN_TOKEN=$(kubectl --context mesh-zone get secrets -n kong-mesh-system admin-user-token -o json | jq -r .data.value | base64 -d)

   kumactl config control-planes add \
     --address http://localhost:5681 \
     --headers "authorization=Bearer $ZONE_USER_ADMIN_TOKEN" \
     --name "my-cp" \
     --overwrite
   ```

1. Export your data plane name:

   ```sh
   DATAPLANE_NAME=$(kumactl get dataplanes -ojson | jq -r '.items[] | select(.networking.inbound[0].tags["kuma.io/service"] == "redis_kong-mesh-demo_svc_6379") | .name')
   ```

Now that we've set up kumactl, we can migrate our policies.

### Migrate TrafficPermissions to MeshTrafficPermission

1. Deploy the new MeshTrafficPermission policy with the `kuma.io/effect: shadow` label:

   ```sh
   echo 'apiVersion: kuma.io/v1alpha1
   kind: MeshTrafficPermission
   metadata:
     namespace: kong-mesh-system
     name: app-to-redis
     labels:
       kuma.io/mesh: default
       kuma.io/effect: shadow
   spec:
     targetRef:
       kind: MeshService
       name: redis_kong-mesh-demo_svc_6379
     from:
       - targetRef:
           kind: MeshSubset
           tags:
             kuma.io/service: demo-app_kong-mesh-demo_svc_5000
         default:
           action: Allow' | kubectl apply -f -
   ```

1. Check the differences between the old and new policies:

   ```sh
   kumactl inspect dataplane $DATAPLANE_NAME --type=config --shadow --include=diff | jq '.diff' | jd -t patch2jd
   ```
   
   You should get the following result:

   ```sh
   @ ["type.googleapis.com/envoy.config.listener.v3.Listener","inbound:10.244.0.7:6379","filterChains",0,"filters",0,"typedConfig","rules","policies","app-to-redis"]
   - {"permissions":[{"any":true}],"principals":[{"authenticated":{"principalName":{"exact":"spiffe://default/demo-app_kong-mesh-demo_svc_5000"}}}]}
   @ ["type.googleapis.com/envoy.config.listener.v3.Listener","inbound:10.244.0.7:6379","filterChains",0,"filters",0,"typedConfig","rules","policies","MeshTrafficPermission"]
   + {"permissions":[{"any":true}],"principals":[{"authenticated":{"principalName":{"exact":"spiffe://default/demo-app_kong-mesh-demo_svc_5000"}}}]}
   ```
   {:.no-copy-code}

1. Remove the `kuma.io/effect: shadow` label from the new policy:

   ```sh
   kubectl label -n kong-mesh-system meshtrafficpermission app-to-redis kuma.io/effect-
   ```

1. Delete the old policy:

   ```sh
   kubectl delete trafficpermissions --all
   ```

### Migrate Timeout to MeshTimeout

1. Deploy the new MeshTimeout policy with the `kuma.io/effect: shadow` label:

   ```sh
   echo 'apiVersion: kuma.io/v1alpha1
   kind: MeshTimeout
   metadata:
     namespace: kong-mesh-system
     name: timeout-global
     labels:
       kuma.io/mesh: default
       kuma.io/effect: shadow
   spec:
     targetRef:
       kind: Mesh
     to:
     - targetRef:
         kind: Mesh
       default:
         connectionTimeout: 21s
         idleTimeout: 22s
         http:
           requestTimeout: 23s
           streamIdleTimeout: 25s
           maxStreamDuration: 26s
     from:
     - targetRef:
         kind: Mesh
       default:
         connectionTimeout: 10s
         idleTimeout: 2h
         http:
           requestTimeout: 0s
           streamIdleTimeout: 2h' | kubectl apply -f-
   ```

1. Check the differences between the old and new policies:

   ```sh
   kumactl inspect dataplane $DATAPLANE_NAME --type=config --shadow --include=diff | jq '.diff' | jd -t patch2jd
   ```
   
   You should get the following result:

   ```sh
   @ ["type.googleapis.com/envoy.config.cluster.v3.Cluster","demo-app_kong-mesh-demo_svc_5000","connectTimeout"]
   - "5s"
   + "21s"
   @ ["type.googleapis.com/envoy.config.cluster.v3.Cluster","demo-app_kong-mesh-demo_svc_5000","typedExtensionProtocolOptions","envoy.extensions.upstreams.http.v3.HttpProtocolOptions","commonHttpProtocolOptions","idleTimeout"]
   - "3600s"
   + "22s"
   @ ["type.googleapis.com/envoy.config.cluster.v3.Cluster","demo-app_kong-mesh-demo_svc_5000","typedExtensionProtocolOptions","envoy.extensions.upstreams.http.v3.HttpProtocolOptions","commonHttpProtocolOptions","maxStreamDuration"]
   - "0s"
   + "26s"
   @ ["type.googleapis.com/envoy.config.cluster.v3.Cluster","localhost:6379","connectTimeout"]
   - "5s"
   + "10s"
   @ ["type.googleapis.com/envoy.config.cluster.v3.Cluster","redis_kong-mesh-demo_svc_6379","connectTimeout"]
   - "5s"
   + "21s"
   @ ["type.googleapis.com/envoy.config.listener.v3.Listener","inbound:10.244.0.7:6379","filterChains",0,"filters",1,"typedConfig","idleTimeout"]
   - "3600s"
   + "7200s"
   @ ["type.googleapis.com/envoy.config.listener.v3.Listener","outbound:10.102.33.12:5000","filterChains",0,"filters",0,"typedConfig","routeConfig","virtualHosts",0,"routes",0,"route","idleTimeout"]
   + "25s"
   @ ["type.googleapis.com/envoy.config.listener.v3.Listener","outbound:10.102.33.12:5000","filterChains",0,"filters",0,"typedConfig","requestHeadersTimeout"]
   + "0s"
   @ ["type.googleapis.com/envoy.config.listener.v3.Listener","outbound:240.0.0.0:80","filterChains",0,"filters",0,"typedConfig","routeConfig","virtualHosts",0,"routes",0,"route","idleTimeout"]
   + "25s"
   @ ["type.googleapis.com/envoy.config.listener.v3.Listener","outbound:240.0.0.0:80","filterChains",0,"filters",0,"typedConfig","requestHeadersTimeout"]
   + "0s"
   ```
   {:.no-copy-code}

1. Remove the `kuma.io/effect: shadow` label from the new policy:

   ```sh
   kubectl label -n kong-mesh-system meshtimeout timeout-global kuma.io/effect-
   ```

1. Delete the old policy:

   ```sh
   kubectl delete timeouts --all
   ```

### Migrate CircuitBreaker to MeshCircuitBreaker

1. Deploy the new MeshCircuitBreaker policy with the `kuma.io/effect: shadow` label:

   ```sh
   echo 'apiVersion: kuma.io/v1alpha1
   kind: MeshCircuitBreaker
   metadata:
     namespace: kong-mesh-system
     name: cb-global
     labels:
       kuma.io/mesh: default
       kuma.io/effect: shadow
   spec:
     targetRef:
       kind: Mesh
     to:
     - targetRef:
         kind: Mesh
       default:
         connectionLimits:
           maxConnections: 24
           maxPendingRequests: 25
           maxRequests: 26
           maxRetries: 27
         outlierDetection:
           interval: 21s
           baseEjectionTime: 22s
           maxEjectionPercent: 23
           splitExternalAndLocalErrors: false
           detectors:
             totalFailures:
               consecutive: 28
             gatewayFailures:
               consecutive: 29
             localOriginFailures:
               consecutive: 30
             successRate:
               requestVolume: 31
               minimumHosts: 32
               standardDeviationFactor: "1.33"
             failurePercentage:
               requestVolume: 34
               minimumHosts: 35
               threshold: 36' | kubectl apply -f-
   ```
1. Check the differences between the old and new policies:

   ```sh
   kumactl inspect dataplane $DATAPLANE_NAME --type=config --shadow --include=diff | jq '.diff' | jd -t patch2jd
   ```
   
   You should get the following result:

   ```sh
   @ ["type.googleapis.com/envoy.config.cluster.v3.Cluster","demo-app_kong-mesh-demo_svc_5000","circuitBreakers","thresholds",0,"trackRemaining"]
   + true
   @ ["type.googleapis.com/envoy.config.cluster.v3.Cluster","redis_kong-mesh-demo_svc_6379","circuitBreakers","thresholds",0,"trackRemaining"]
   + true
   ```
   {:.no-copy-code}
   
1. Remove the `kuma.io/effect: shadow` label from the new policy:
   ```sh
   kubectl label -n kong-mesh-system meshcircuitbreaker cb-global kuma.io/effect-
   ```

1. Delete the old policy:
   ```sh
   kubectl delete circuitbreakers --all
   ```

### Migrate TrafficRoute

It’s safe to simply remove the `TrafficRoute`. Traffic will flow through the system even if there are neither `TrafficRoute` nor `MeshTCPRoute`/`MeshHTTPRoute` resources:

```sh
kubectl delete trafficroute --all
```

## Migrate Gateway Routes

There are two different protocols available to replace `MeshGatewayRoute`: one for HTTP and one for TCP. If both exist, `MeshHTTPRoute` takes precedence over `MeshTCPRoute`.

The high-level structure of the Routes is the same, though there are a number of details to consider. Some enum values and some field structures were updated, largely to reflect Gateway API.

The main consideration is specifying which gateways are affected by the Route. The most important change with the new resources is that instead of solely using tags to select `MeshGateway` listeners, new Routes target `MeshGateway` resources by name, and optionally with tags for specific listeners.

### Deploy a gateway

To test the Route migration, let's start by creating the `MeshGateway` and `MeshGatewayInstance` resources:

```sh
echo "
apiVersion: kuma.io/v1alpha1
kind: MeshGateway
mesh: default
metadata:
  name: demo-app
  labels:
    kuma.io/origin: zone
spec:
  conf:
    listeners:
    - port: 80
      protocol: HTTP
      tags:
        port: http-80
  selectors:
  - match:
      kuma.io/service: demo-app-gateway_kong-mesh-demo_svc
---
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayInstance
metadata:
  name: demo-app-gateway
  namespace: kong-mesh-demo
spec:
  replicas: 1
  serviceType: LoadBalancer" | kubectl apply -f-
```

### Deploy a Route with MeshGatewayRoute

Use the following command to create a new Route using the old `MeshGatewayRoute` resource:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshGatewayRoute
mesh: default
metadata:
  name: demo-app-gateway
spec:
  conf:
   http:
    hostnames:
    - example.com
    rules:
    - matches:
      - path:
          match: PREFIX
          value: /
      backends:
      - destination:
          kuma.io/service: demo-app_kong-mesh-demo_svc_5000
        weight: 1
  selectors:
  - match:
      kuma.io/service: demo-app-gateway_kong-mesh-demo_svc" | kubectl apply -f-
```

Here you can see that the gateway is targeted using this structure:

```yaml
spec:
  selectors:
    - match:
        kuma.io/service: demo-app-gateway_kuma-demo_svc
        port: http-80
```
{:.no-copy-code}

### Deploy a Route using MeshHTTPRoute

1. Use the following command to create the new `MeshHTTPRoute`:

   ```sh
   echo "apiVersion: kuma.io/v1alpha1
   kind: MeshHTTPRoute
   metadata:
     name: demo-app
     namespace: kong-mesh-system
     labels:
       kuma.io/origin: zone
       kuma.io/mesh: default
   spec:
     targetRef:
       kind: MeshGateway
       name: demo-app
     to:
     - targetRef:
         kind: Mesh
       hostnames:
         - example.com
       rules:
       - default:
           backendRefs:
           - kind: MeshService
             name: demo-app_kong-mesh-demo_svc_5000
         matches:
         - path:
             type: PathPrefix
             value: /" | kubectl apply -f -
   ```
   
   In this new resource, the gateway is targeted using the name of the gateway:
   
   ```yaml
   spec:
     targetRef:
       kind: MeshGateway
       name: demo-app
       tags:
         port: http-80
     to:
   ```
   {:.no-copy-code}

   1. Delete the `MeshGatewayRoute`
   
   ```sh
   kubectl delete meshgatewayroute --all
   ```