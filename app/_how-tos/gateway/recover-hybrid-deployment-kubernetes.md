---
title: Recover a self-managed hybrid {{site.base_gateway}} deployment after a Kubernetes cluster loss
short_title: Recover a hybrid deployment
description: "Back up the PostgreSQL database and Helm releases of a self-managed {{site.base_gateway}} hybrid deployment, then restore the control plane and data plane in a replacement Kubernetes cluster."
content_type: how_to

permalink: /how-to/recover-hybrid-deployment-after-cluster-loss/
breadcrumbs:
  - /gateway/
  - /gateway/disaster-recovery/kubernetes/

products:
  - gateway

works_on:
  - on-prem

entities: []

tags:
  - kubernetes
  - backup
  - restore
  - failover

tldr:
  q: How do I recover a self-managed hybrid {{site.base_gateway}} deployment after I lose its Kubernetes cluster?
  a: |
    Before the failure, take a `pg_dump` backup of the {{site.base_gateway}} database, and save the Helm values, the chart archive, the cluster certificate, and the license.
    In the replacement cluster, restore the backup into an empty database, then install the control plane with migrations turned off, and install the data plane.

prereqs:
  skip_product: true
  inline:
    - title: Create a k3d cluster
      position: before
      icon_url: /assets/icons/kubernetes.svg
      include_content: prereqs/kubernetes/k3d-dr-cluster
    - title: "{{site.ee_product_name}} license"
      icon_url: /assets/icons/gateway.svg
      content: |
        Save your {{site.ee_product_name}} license as `license.json` in your working directory.
        Run every command in this guide from that directory.
    - title: "{{site.base_gateway}} in hybrid mode"
      icon_url: /assets/icons/gateway.svg
      include_content: prereqs/kubernetes/hybrid-dr-deployment

related_resources:
  - text: Recover a self-managed hybrid deployment on Kubernetes
    url: /gateway/disaster-recovery/kubernetes/hybrid/
  - text: Prepare for disaster recovery on Kubernetes
    url: /gateway/disaster-recovery/kubernetes/prepare/
  - text: Back up and restore {{site.base_gateway}}
    url: /gateway/upgrade/backup-and-restore/

cleanup:
  inline:
    - title: Delete the k3d cluster and the recovery files
      icon_url: /assets/icons/kubernetes.svg
      content: |
        ```bash
        k3d cluster delete kong-dr
        rm -rf recovery
        ```

automated_tests: false
---

In a self-managed [hybrid mode](/gateway/hybrid-mode/) deployment, the control plane stores the {{site.base_gateway}} configuration in PostgreSQL.
When you lose the cluster and its database, you restore the database from a backup, start a control plane on top of it, and connect new data planes.
The recovered configuration is the configuration at the time of the backup.

For what to save, Keyring recovery, and how to adapt the procedure to an external database, see [Recover a self-managed hybrid deployment on Kubernetes](/gateway/disaster-recovery/kubernetes/hybrid/).

## Record the baseline response

1. Export the address of the data plane proxy:

   ```bash
   export PROXY_IP=$(kubectl get service --namespace kong kong-dp-kong-proxy -o jsonpath='{range .status.loadBalancer.ingress[0]}{@.ip}{@.hostname}{end}')
   echo $PROXY_IP
   ```

1. Send a request through the data plane to record the baseline response:

   ```bash
   curl -i "http://$PROXY_IP/dr-check/anything"
   ```

   You'll see an `HTTP/1.1 200 OK` response from httpbin.

## Save the recovery set

In production, the recovery set lives in protected storage outside the cluster.
In this guide, a local `recovery` directory plays that role.

1. Create the directory:

   ```bash
   mkdir -p recovery
   ```

1. Take a complete backup of the `kong` database in the PostgreSQL custom format.
   The command runs `pg_dump` inside the database pod, so you don't need a local PostgreSQL client:

   ```bash
   kubectl exec -n kong deployment/kong-db -- pg_dump -U kong --format=custom --dbname=kong > recovery/kong.dump
   ```

   Record the time of the backup.
   Changes that you make after this point aren't in the recovered configuration.

{% include k8s/disaster-recovery/save-helm-release.md release="kong-cp" namespace="kong" chart="kong/kong" values_file="values-cp.yaml" version_var="GATEWAY_CHART_VERSION" %}

1. Save the effective Helm values of the `kong-dp` release:

   ```bash
   helm get values kong-dp -n kong --all -o yaml > recovery/values-dp.yaml
   ```

1. Save the database manifest, the cluster certificate, its key, and the license:

   ```bash
   cp postgres.yaml tls.crt tls.key license.json recovery/
   ```

## Simulate the cluster loss

Delete the cluster.
The control plane, the data plane, and the database with its data are deleted with it:

```bash
k3d cluster delete kong-dr
```

## Create the replacement cluster

Create a new, empty cluster with the same name:

{% include k8s/disaster-recovery/k3d-cluster.md %}

## Restore the database

1. Create the `kong` namespace:

   ```bash
   kubectl create namespace kong
   ```

1. Deploy an empty database with the saved manifest.
   It has the same name as the original, so the saved control plane values still point to it:

   ```bash
   kubectl apply -f recovery/postgres.yaml
   ```

1. Wait for the database:

   ```bash
   kubectl rollout status deployment/kong-db -n kong --timeout=300s
   ```

1. Restore the backup into the empty database:

   ```bash
   kubectl exec -i -n kong deployment/kong-db -- pg_restore -U kong --dbname=kong --exit-on-error < recovery/kong.dump
   ```

   The command restores the schema and the data together, and exits without output when it succeeds.

## Restore the control plane

1. Restore the license Secret:

   ```bash
   kubectl create secret generic kong-enterprise-license -n kong \
     --from-file=license=recovery/license.json
   ```

1. Restore the cluster certificate Secret:

   ```bash
   kubectl create secret tls kong-cluster-cert -n kong \
     --cert=recovery/tls.crt --key=recovery/tls.key
   ```

1. Create an override file that turns off the migration jobs.
   The restored database already has the {{site.base_gateway}} schema, so the chart must not bootstrap or migrate it:

   ```bash
   cat <<EOF > recovery/restore-values.yaml
   migrations:
     init: false
     preUpgrade: false
     postUpgrade: false
   EOF
   ```

1. Install the control plane with the saved values and the override file:

   ```bash
   helm install kong-cp "recovery/kong-${GATEWAY_CHART_VERSION}.tgz" -n kong \
     -f recovery/values-cp.yaml -f recovery/restore-values.yaml \
     --wait --timeout 5m
   ```

1. Forward the Admin API port of the new control plane in the background:

   ```bash
   kubectl port-forward -n kong service/kong-cp-kong-admin 8001 > /dev/null 2>&1 &
   ```

1. Read the Route from the restored database:

   ```bash
   curl --fail-with-body localhost:8001/routes/dr-check
   ```

   You'll see the `dr-check` Route with its original ID.

## Restore the data plane

The saved data plane values point to the `kong-cp` Services in the `kong` namespace.
The new control plane has the same Service names, so the data plane finds it.

Install the data plane with the saved values:

```bash
helm install kong-dp "recovery/kong-${GATEWAY_CHART_VERSION}.tgz" -n kong \
  -f recovery/values-dp.yaml --wait --timeout 5m
```

## Validate

1. The replacement data plane has a new load balancer address.
   Export it:

   ```bash
   export PROXY_IP=$(kubectl get service --namespace kong kong-dp-kong-proxy -o jsonpath='{range .status.loadBalancer.ingress[0]}{@.ip}{@.hostname}{end}')
   echo $PROXY_IP
   ```

1. Send the baseline request again:

   ```bash
   curl -i "http://$PROXY_IP/dr-check/anything"
   ```

   You'll see the same `HTTP/1.1 200 OK` response from httpbin.

1. To make sure that the recovered control plane distributes new configuration, send a request to a path that the `dr-check` Route doesn't match yet:

   ```bash
   curl -s -o /dev/null -w "%{http_code}\n" "http://$PROXY_IP/dr-verify/anything"
   ```

   You'll see `404`.

1. Add the `/dr-verify` path to the Route:

   ```bash
   curl -X PATCH localhost:8001/routes/dr-check \
     -d "paths[]=/dr-check" -d "paths[]=/dr-verify"
   ```

1. Wait a few seconds, then send the request again:

   ```bash
   curl -s -o /dev/null -w "%{http_code}\n" "http://$PROXY_IP/dr-verify/anything"
   ```

   You'll see `200`.
