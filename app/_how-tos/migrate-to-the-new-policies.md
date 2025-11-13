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
  q: ""
  a: ""

prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: Install kumactl
      include_content: prereqs/tools/kumactl
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster
---

```sh
helm repo add kong-mesh https://kumahq.github.io/charts
helm repo update
helm install --create-namespace --namespace kong-mesh-system kong-mesh kong-mesh/kong-mesh --set "controlPlane.defaults.skipMeshCreation=true"
``` 

```sh
kubectl get meshes
```

```sh
No resources found
```
{.no-copy-code}

```sh
echo 'apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  # for the purpose of this guide we want to setup mesh with old policies first,
  # that is why we are skipping the default policies creation
  skipCreatingInitialPolicies: ["*"] ' | kubectl apply -f-
```


```sh
echo "
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
          image: 'redis'
          ports:
            - name: tcp
              containerPort: 6379
          lifecycle:
            preStop: # delay shutdown to support graceful mesh leave
              exec:
                command: ['/bin/sleep', '30']
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
                    echo 'Redis not ready after 30s, skipping postStart'
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
          image: 'kumahq/kong-mesh-demo'
          env:
            - name: REDIS_HOST
              value: 'redis.kong-mesh-demo.svc.cluster.local'
            - name: REDIS_PORT
              value: '6379'
            - name: APP_VERSION
              value: '1.0'
            - name: APP_COLOR
              value: '#efefef'
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
    port: 5000" | kubectl apply -f -

kubectl wait -n kong-mesh-demo --for=condition=ready pod --selector=app=demo-app --timeout=90s
```

```sh
kubectl port-forward svc/demo-app -n kong-mesh-demo 5000:5000
```

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
        type: builtin' | kubectl apply -f-
```

```sh
echo 'apiVersion: kuma.io/v1alpha1
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
        kuma.io/service: redis_kong-mesh-demo_svc_6379' | kubectl apply -f -
```

```sh
echo 'apiVersion: kuma.io/v1alpha1
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
      kuma.io/service: "*"' | kubectl apply -f-
```

```sh
echo 'apiVersion: kuma.io/v1alpha1
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
      maxStreamDuration: 26s' | kubectl apply -f-
```

```sh
echo 'apiVersion: kuma.io/v1alpha1
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

```sh
kubectl --context mesh-zone port-forward svc/kuma-control-plane -n kuma-system 5681:5681
```

```sh
export ZONE_USER_ADMIN_TOKEN=$(kubectl --context mesh-zone get secrets -n kong-mesh-system admin-user-token -o json | jq -r .data.value | base64 -d)
kumactl config control-planes add \
  --address http://localhost:5681 \
  --headers "authorization=Bearer $ZONE_USER_ADMIN_TOKEN" \
  --name "new-cp" \
  --overwrite
```

```sh
DATAPLANE_NAME=$(kumactl get dataplanes -ojson | jq '.items[] | select(.networking.inbound[0].tags["kuma.io/service"] == "redis_kong-mesh-demo_svc_6379") | .name')
kumactl inspect dataplane ${DATAPLANE_NAME} --type=config --shadow --include=diff | jq '.diff' | jd -t patch2jd
```

```sh

```
{.no-copy-code}

```sh
kubectl label -n kong-mesh-system meshtrafficpermission app-to-redis kuma.io/effect-
```

```sh
kubectl delete trafficpermissions --all
```

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

```sh
kumactl inspect dataplane ${DATAPLANE_NAME} --type=config --shadow --include=diff | jq '.diff' | jd -t patch2jd
```

```sh

```
{.no-copy-code}

```sh
kubectl label -n kong-mesh-system meshtimeout timeout-global kuma.io/effect-
```

```sh
kubectl delete timeouts --all
```

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

```sh
kumactl inspect dataplane ${DATAPLANE_NAME} --type=config --shadow --include=diff | jq '.diff' | jd -t patch2jd
```

```sh
kubectl label -n kong-mesh-system meshcircuitbreaker cb-global kuma.io/effect-
```

```sh
kubectl delete circuitbreakers --all
```

```sh
echo "---
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

```sh
kubectl delete meshgatewayroute --all
```