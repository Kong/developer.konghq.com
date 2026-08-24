---
title: How to check DNS querying when Kong is installed in k8s
content_type: support
description: Explains how to inspect the DNS queries Kong makes in Kubernetes by enabling query logging in the cluster's CoreDNS configuration.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I check the DNS queries Kong makes when it's installed in Kubernetes?
  a: |
    Kong resolves DNS through the cluster's CoreDNS service, which doesn't log query details by default. Add the `log` and `whoami` plugins to CoreDNS's Corefile (in the `coredns` ConfigMap in the `kube-system` namespace), apply the updated ConfigMap, and restart the CoreDNS deployment. Then tail the CoreDNS pod logs to see each DNS query and its result, for example `NOERROR` for a successful lookup or `NXDOMAIN` when the name doesn't resolve.
related_resources:
  - text: CoreDNS log plugin documentation
    url: https://coredns.io/plugins/log/#examples
---

## Overview

When Kong is installed in k8s, kong will send DNS query to DNS server. How can we check DNS query results?

## Steps

K8S uses `coredns` pods as DNS server by default, you could find `coredns` in the `kube-system` namespace as below

```bash

kubectl get all -n kube-system
NAME                                         READY   STATUS    RESTARTS   AGE
pod/coredns-558bd4d5db-9tmw2                 1/1     Running   1          64d
pod/coredns-558bd4d5db-bzlnq                 1/1     Running   2          64d

NAME               TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
service/kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   64d

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/coredns   2/2     2            2           64d

NAME                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/coredns-558bd4d5db   2         2         2       64d
```

Step 0: Let's create below upstream/target/service/route for testing

```bash

# create httpbin upstream
curl <kong>:<kong-admin-port>/upstreams -H "kong-admin-token:admin" \
-d 'name=httpbin'

# create target with existing service: http://httpbin.org:80
curl <kong>:<kong-admin-port>/upstreams/httpbin/targets -H "kong-admin-token:admin" \
-d 'target=httpbin.org:80'

# create target with dummy service: http://httpbin.org.dummy:80
curl <kong>:<kong-admin-port>/upstreams/httpbin/targets -H "kong-admin-token:admin" \
-d 'target=httpbin.org.dummy:80'

# create service
curl <kong>:<kong-admin-port>/services -H "kong-admin-token:admin" \
-d 'name=httpbin' \
-d 'host=httpbin' \
-d 'path=/anything'

# create route
curl <kong>:<kong-admin-port>/services/httpbin/routes -H "kong-admin-token:admin" \
-d 'name=httpbin' \
-d 'paths=/test'

# testing
curl <kong>:<kong-proxy-port>/test -i
>200 response
```

`coredns` does not show DNS query access and result in log by default.

We need to modify `coredns` configuration as below

Step 1: Get original `coredns` config

```bash

kubectl get configmap coredns -n kube-system -o yaml > coredns.yaml
```

Step 2: Modify `coredns` config as below

# Please modify this file based on your environment. you have to add "log" and "`whoami`" into it.

```yaml

vi coredns.yaml

apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
+       log
+       whoami
        errors
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf {
           max_concurrent 1000
        }
        cache 30
        loop
        reload
        loadbalance
    }
```

Step 3: Apply new `coredns` config

```bash

kubectl apply -f coredns.yaml
configmap/coredns configured

# Restart coredns
kubectl rollout restart deployments/coredns -n kube-system
deployment.apps/coredns restarted
```

Step 4: Check `coredns` log

```bash

kubectl logs -f <coredns-pod-name> -n kube-system

Then you will be able to see below log
[INFO] 10.1.3.45:49488 - 31240 "A IN httpbin.org. udp 29 false 512" NOERROR qr,aa,rd,ra 191 0.0001016s

It shows query result for "A IN httpbin.org" is "NOERROR"(success) and DNS response time is 0.0001016s.

You will be able to see below log too
[INFO] 10.1.3.46:43281 - 44662 "A IN httpbin.org.dummy. udp 35 false 512" NXDOMAIN qr,rd,ra 35 0.0079283s

It shows query result for "A IN httpbin.org.dummy" is "NXDOMAIN"(not found) and DNS response time is 0.0079283s
```
