---
title: "Recover a self-managed hybrid deployment on Kubernetes"
description: "Recover a self-managed Kong Gateway hybrid deployment, including PostgreSQL, control planes, data planes, and keyring material."
content_type: reference
layout: reference
breadcrumbs:
  - /gateway/
  - /gateway/disaster-recovery/kubernetes/
products:
  - gateway
works_on:
  - on-prem
tags:
  - kubernetes
  - backup
  - restore
  - failover
related_resources:
  - text: Prepare for disaster recovery
    url: /gateway/disaster-recovery/kubernetes/prepare/
  - text: Test disaster recovery
    url: /gateway/disaster-recovery/kubernetes/test/
  - text: Back up and restore Kong Gateway
    url: /gateway/upgrade/backup-and-restore/
  - text: Keyring recovery
    url: /gateway/keyring/#disaster-recovery
---

You can recover a self-managed [hybrid mode](/gateway/hybrid-mode/) deployment on Kubernetes when you lose the {{site.base_gateway}} cluster and its database.
Restore the control plane from a PostgreSQL backup, then reconnect replacement Kubernetes data planes.
This walkthrough uses a full logical database backup and the same {{site.base_gateway}} version as the original deployment.

The result is a new control plane that serves the configuration from the backup.
This procedure doesn't recover changes that you made after the backup.

## Starting deployment and recovery inputs

The hybrid recovery example uses the release layout from [Install {{site.base_gateway}} on Kubernetes](/gateway/install/kubernetes/on-prem/):

* Helm releases: `kong-cp` and `kong-dp`
* Chart: `kong/kong`
* Namespace: `kong`
* PostgreSQL database and role: `kong`

The example restores into a separate PostgreSQL instance with an empty database named `kong`, owned by the `kong` role.
Provision that instance and role before you restore.
The instance must use a PostgreSQL version that {{site.base_gateway}} supports.
Both the recovery workstation and the control plane must be able to reach it.

Set these variables:

{% table %}
columns:
  - title: Variable
    key: variable
  - title: Value
    key: value
rows:
  - variable: "`PRIMARY_CONTEXT`"
    value: Original Kubernetes context
  - variable: "`RECOVERY_CONTEXT`"
    value: Replacement Kubernetes context
  - variable: "`PRIMARY_PG_HOST`"
    value: Original PostgreSQL host, used only to take the backup
  - variable: "`RECOVERY_PG_HOST`"
    value: Replacement PostgreSQL host
  - variable: "`KONG_ADMIN_TOKEN`"
    value: Existing Admin API token, if RBAC is enabled
{% endtable %}

Use PostgreSQL clients that are compatible with the source server.
Supply database credentials through a protected PostgreSQL password file, and keep the TLS settings that your database requires.
The commands use the standard PostgreSQL port.
If your port is different, add `--port` to the commands.

Before the failure, create a Gateway Service and a Route named `dr-check` in the default Workspace.
They must serve a known upstream through `/dr-check`.
Record a successful response, and an authentication rejection if the Route is protected.
New Routes accept only HTTPS unless you set `protocols`, so the requests in this guide use `https://`.

## Save the database and deployment files

{% include k8s/disaster-recovery/save-helm-release.md dir="hybrid" release="kong-cp" namespace="kong" chart="kong/kong" values_file="values-cp.yaml" version_var="GATEWAY_CHART_VERSION" %}

Save the effective Helm values of the `kong-dp` release:

```bash
helm get values kong-dp -n kong --kube-context "$PRIMARY_CONTEXT" \
  --all -o yaml > recovery/hybrid/values-dp.yaml
```

Take a complete database backup in the PostgreSQL custom format:

```bash
pg_dump --host="$PRIMARY_PG_HOST" --username=kong --dbname=kong \
  --format=custom --file=recovery/hybrid/kong.dump
```

Record the time of the backup and the last configuration change that it includes.
The `pg_dump` command backs up the database only.
It doesn't back up PostgreSQL roles, cloud resources, or certificate files.

Also save the following files:

* The `kong-cluster-cert` certificate and private key, as `tls.crt` and `tls.key`
* The license, as `license.json`
* Any database Secret, custom plugins, registry credentials, or externally referenced secrets

If [Keyring](/gateway/keyring/) is enabled, also save its recovery private key as `keyring-recovery.pem`, and the Secret that mounts the public key named by `keyring_recovery_public_key`.
Make sure that you configured Keyring recovery before you took this backup.

Record the exact {{site.base_gateway}} image, so that recovery doesn't select a newer image.

## Restore the database before starting Kong

Isolate the former database writer and pause configuration pipelines.
During a drill, keep production management tools away from the recovery database.
Don't let two independent control planes accept changes that are meant for one authoritative environment.

Restore the backup into the empty recovery database:

```bash
pg_restore --host="$RECOVERY_PG_HOST" --username=kong --dbname=kong \
  --exit-on-error recovery/hybrid/kong.dump
```

Expect the command to exit successfully without restore errors.
The `pg_restore` command restores the schema and the data together.
Don't bootstrap Kong into the empty database before this restore.
If the restore fails partway through, recreate an empty recovery database before you try again.
Don't accept a partial restore.
For more information, see the [PostgreSQL restore reference](https://www.postgresql.org/docs/current/app-pgrestore.html).

Create an override file that points the control plane at the recovery database.
The file also turns off migration jobs, because this restore uses the same version:

```yaml
env:
  pg_host: <RECOVERY_PG_HOST>
migrations:
  init: false
  preUpgrade: false
  postUpgrade: false
```

Replace `<RECOVERY_PG_HOST>` with the endpoint of the recovery database, and save the file as `recovery/hybrid/restore-values.yaml`.
Don't change `values-cp.yaml`, because the values in this override take precedence.
If the database name, role, password or Secret reference, or TLS settings are also different, override them in this file too.
Don't change the saved {{site.base_gateway}} image.

Make sure that the saved chart supports these settings.
The [Kong chart migration template](https://github.com/Kong/charts/blob/main/charts/kong/templates/migrations.yaml) uses `migrations.init` to control the bootstrap job that runs at install time.

## Restore credentials and the control plane

Make sure that `RECOVERY_CONTEXT` points to the replacement cluster, then create its namespace:

```bash
kubectl --context "$RECOVERY_CONTEXT" create namespace kong
```

Restore the cluster certificate:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong create secret tls kong-cluster-cert \
  --cert=recovery/hybrid/tls.crt --key=recovery/hybrid/tls.key
```

Restore the license Secret that the installation example uses:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong create secret generic kong-enterprise-license \
  --from-file=license=recovery/hybrid/license.json
```

Before you install, restore any other Secrets that the saved values reference, including the Secret for the Keyring recovery public key.
If a Secret volume is missing, the pod doesn't start.

Deploy the control plane with the saved values and the override file:

```bash
helm install kong-cp "recovery/hybrid/kong-${GATEWAY_CHART_VERSION}.tgz" \
  --kube-context "$RECOVERY_CONTEXT" -n kong \
  -f recovery/hybrid/values-cp.yaml -f recovery/hybrid/restore-values.yaml \
  --wait --timeout 5m
```

If startup fails, inspect the control plane logs for database authentication, TLS, schema, or Keyring errors.
Don't run migrations to work around a mismatch between the saved database and the {{site.base_gateway}} image.

In a separate terminal, forward the private Admin API port:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong port-forward \
  service/kong-cp-kong-admin 8001:8001
```

Read the Route from the restored database:

```bash
curl --fail-with-body -H "Kong-Admin-Token: $KONG_ADMIN_TOKEN" \
  http://localhost:8001/routes/dr-check
```

Expect the saved Route, including its ID and the `/dr-check` path.
For a different Workspace, use the Admin API path of that Workspace.
The local HTTP port forward follows the installation example.
If HTTP is disabled, use the private TLS endpoint of your deployment.

### Recover Keyring, if enabled

The restored database contains the encrypted Keyring material, but the new control plane starts with an empty Keyring.
Until you recover the Keyring, Admin API reads of encrypted entities fail with HTTP `500`.

Submit the recovery private key:

```bash
curl --fail-with-body -X POST \
  -H "Kong-Admin-Token: $KONG_ADMIN_TOKEN" \
  -F recovery_private_key=@recovery/hybrid/keyring-recovery.pem \
  http://localhost:8001/keyring/recover
```

Inspect the recovered and failed keys in the response.
Set `KEY_ID` to the recovered key that you want to activate, then activate it:

```bash
curl --fail-with-body -X POST \
  -H "Kong-Admin-Token: $KONG_ADMIN_TOKEN" \
  --data-urlencode "key=$KEY_ID" http://localhost:8001/keyring/activate
```

Send a request that uses encrypted configuration, and make sure that it succeeds.
A restored Route alone doesn't show that encrypted credentials work.
For the required preparation, see [Keyring recovery](/gateway/keyring/#disaster-recovery).

## Restore and test the data plane

The original data plane values reference the `kong-cp` Services in the `kong` namespace.
If you keep those names, the replacement data plane finds the new control plane.
If you used external control plane names, update those endpoints and their trust settings in `values-dp.yaml`.

Install the data plane:

```bash
helm install kong-dp "recovery/hybrid/kong-${GATEWAY_CHART_VERSION}.tgz" \
  --kube-context "$RECOVERY_CONTEXT" -n kong \
  -f recovery/hybrid/values-dp.yaml --wait --timeout 5m
```

Read its proxy address:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong get service kong-dp-kong-proxy
```

Set `RECOVERY_ADDRESS` to the external address, and send a request to the saved Route:

```bash
curl --fail-with-body --insecure "https://${RECOVERY_ADDRESS}/dr-check"
```

Expect the same application result that you recorded before the backup.
Use `--insecure` only for this direct-address check.
The replacement proxy presents its default self-signed certificate unless you configured your own certificate.
If the Route uses a hostname, TLS, or authentication, add them to the request.

If the request fails, check the status code:

* `404`: The expected Route isn't loaded or doesn't match. Inspect control plane synchronization before you move traffic.
* `426`: The Route accepts only HTTPS.

{% include k8s/disaster-recovery/verify-config-update.md owner="through your normal configuration workflow" %}

## Move traffic and fail back

Update the DNS record or external load balancer target of the application to the validated proxy address.
Then repeat the baseline requests through the normal client endpoint.

Treat the recovered database as authoritative.
To fail back, do the following:

1. Synchronize the original database from the recovered state through your PostgreSQL recovery procedure.
1. Switch the control plane to the accepted writer.
1. Validate the original data planes.
1. Return traffic to the original data planes.

Don't reconnect the old database as an independent writer.
Its changes don't merge with the recovered database.

In the [drill record](/gateway/disaster-recovery/kubernetes/test/#record-the-results), record the following:

* The backup time
* The configuration changes that are missing
* The results of the encrypted-credential checks
* The traffic recovery time and the configuration recovery time
