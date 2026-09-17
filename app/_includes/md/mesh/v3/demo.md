```sh
cat <<'EOF' > demo.yaml
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
            preStop:
              exec:
                command: ["/bin/sleep", "30"]
            postStart:
              exec:
                command:
                  - /bin/sh
                  - -c
                  - |
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
    port: 5000
EOF
```
{:.collapsible}