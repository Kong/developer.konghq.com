---
title: How to enable Data Plane Resilience when using Helm
content_type: support
description: "How to achieve Data Plane Resilience with the Kong Helm chart by separating the config-exporter data plane from the data plane that proxies traffic."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I enable Data Plane Resilience when deploying Kong with Helm?
  a: |
    The Kong Helm chart has no setting to stop a data plane from proxying traffic, so a node used only to export config to fallback storage (via `cluster_fallback_config_storage` and `cluster_fallback_config_import`) can't be prevented from also serving requests. The workaround is to deploy two separate data plane node groups with Helm — one dedicated to the config-exporter role and one for routing traffic — and send client traffic only to the second node group (for example, by leaving the exporter's Service out of your load balancer).
related_resources:
  - text: Data Plane Resilience documentation
    url: /gateway/cp-outage/
  - text: Example minimal Kong Enterprise hybrid data plane Helm values
    url: https://github.com/Kong/charts/blob/main/charts/kong/example-values/minimal-kong-enterprise-hybrid-data.yaml
---

## Overview

I would like to enable Data Plane Resilience, but I can't find anything in the Kong helm charts for this.

## Steps

The backup node can be a data plane or a control plane node.

We will use a data plane node as an example. It cannot be stopped from taking traffic, e.g. turning off proxy listen for the data plane would produce errors. Hence the approach would be to not direct traffic to it, e.g. not to add it to the load balancer or have a different deployment for this node.

More specifically, since there's no config that would prohibit the exporter data plane node from proxying traffic, the solution would be to create two different dataplanes, i.e. one for the configuration exporter and one for routing traffic, and only use the second one for all requests.

For example based on the config shown here, there could be two different configurations, one for the exporter and one for the importer.

e.g. similar to

```yaml
> cat data-importer.yaml

image:
repository: kong/kong-gateway
tag: "3.14"

env:
role: data_plane
cluster_control_plane: URL:8005
cluster_telemetry_endpoint: URL:8006
lua_ssl_trusted_certificate: /etc/secrets/kong-cluster-cert/tls.crt
cluster_cert: /etc/secrets/kong-cluster-cert/tls.crt
cluster_cert_key: /etc/secrets/kong-cluster-cert/tls.key
cluster_fallback_config_storage: s3://test-bucket/test-prefix
cluster_fallback_config_import: "on"

customEnv:
AWS_REGION: 'us-east-2'
AWS_ACCESS_KEY_ID: XXX
AWS_SECRET_ACCESS_KEY: XXX

secretVolumes:
- kong-cluster-cert

ingressController:
enabled: false

enterprise:
enabled: true
# See instructions regarding enterprise licenses at https://github.com/Kong/charts/blob/master/charts/kong/README.md#kong-enterprise-license
license_secret: kong-enterprise-license # CHANGEME
vitals:
enabled: false

manager:
enabled: false

portal:
enabled: false

portalapi:
enabled: false

proxy:
http:
servicePort: 8001
containerPort: 8000

tls:
servicePort: 8444
containerPort: 8443
parameters:
- http2
```

```
❯ k get all -n kong
NAME READY STATUS RESTARTS AGE
pod/my-controlplane-kong-5c4d5f4cfd-svcdg 0/1 Init:0/2 0 22m
pod/my-controlplane-kong-init-migrations-qzdjf 0/1 Init:0/1 0 22m
pod/my-controlplane-postgresql-0 1/1 Running 0 22m
pod/my-dataplane-exporter1-kong-84966fb599-4x4bd 0/1 Init:0/1 0 6m2s
pod/my-dataplane-importer1-kong-789567c6fb-6zs4f 0/1 Init:0/1 0 4s

NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
...
...
service/my-dataplane-exporter1-kong-proxy LoadBalancer 10.99.130.222 localhost 8000:31120/TCP,8443:30266/TCP 6m2s
service/my-dataplane-importer1-kong-proxy LoadBalancer 10.98.75.141 localhost 8001:30414/TCP,8444:31552/TCP 4s

NAME READY UP-TO-DATE AVAILABLE AGE
deployment.apps/my-controlplane-kong 0/1 1 0 22m
deployment.apps/my-dataplane-exporter1-kong 0/1 1 0 6m2s
deployment.apps/my-dataplane-importer1-kong 0/1 1 0 4s

NAME DESIRED CURRENT READY AGE
replicaset.apps/my-controlplane-kong-5c4d5f4cfd 1 1 0 22m
replicaset.apps/my-dataplane-exporter1-kong-84966fb599 1 1 0 6m2s
replicaset.apps/my-dataplane-importer1-kong-789567c6fb 1 1 0 4s

NAME READY AGE
statefulset.apps/my-controlplane-postgresql 1/1 22m

NAME COMPLETIONS DURATION AGE
job.batch/my-controlplane-kong-init-migrations 0/1 22m 22m
```
