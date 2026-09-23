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

Restore a self-managed hybrid control plane from a PostgreSQL backup, then reconnect replacement Kubernetes data planes. This walkthrough uses a full logical database backup and the same Gateway version as the original deployment.

The failure is loss of the Gateway cluster and its database. The result is a new control plane serving the configuration present in the backup. Changes made after the backup are not recovered by this procedure.

## Starting deployment and recovery inputs

Use the release layout from [Install Kong Gateway on Kubernetes](/gateway/install/kubernetes/on-prem/): Helm releases `kong-cp` and `kong-dp`, chart `kong/kong`, namespace `kong`, and PostgreSQL database and role `kong`.

The example restores into a separate PostgreSQL instance with an empty database named `kong`, owned by the `kong` role. Provision that instance and role before restoring. It must use a Gateway-supported PostgreSQL version and be reachable from both the recovery workstation and control plane.

Set these variables:

| Variable | Value |
| --- | --- |
| `PRIMARY_CONTEXT` | Original Kubernetes context |
| `RECOVERY_CONTEXT` | Replacement Kubernetes context |
| `PRIMARY_PG_HOST` | Original PostgreSQL host, used only when taking the backup |
| `RECOVERY_PG_HOST` | Replacement PostgreSQL host |
| `GATEWAY_CHART_VERSION` | Original `kong/kong` chart version |
| `KONG_ADMIN_TOKEN` | Existing Admin API token, if RBAC is enabled |

Use PostgreSQL clients compatible with the source server. Supply database credentials through a protected PostgreSQL password file and retain the TLS settings required by your database. The commands assume the standard PostgreSQL port; supply `--port` if yours differs.

Before the failure, create a Service and Route named `dr-check` in the default Workspace that serve a known upstream through `/dr-check`. Record a successful response and an authentication rejection if the Route is protected.

## Save the database and deployment files

Create the protected backup directory:

```bash
mkdir -p recovery/hybrid
```

Take a complete database backup in PostgreSQL custom format:

```bash
pg_dump --host="$PRIMARY_PG_HOST" --username=kong --dbname=kong \
  --format=custom --file=recovery/hybrid/kong.dump
```

Record its creation time and the last configuration change included in it. This is a database backup, not a backup of PostgreSQL roles, cloud resources, or certificate files.

Save the control plane values:

```bash
helm get values kong-cp -n kong --kube-context "$PRIMARY_CONTEXT" \
  --all -o yaml > recovery/hybrid/values-cp.yaml
```

Save the data plane values:

```bash
helm get values kong-dp -n kong --kube-context "$PRIMARY_CONTEXT" \
  --all -o yaml > recovery/hybrid/values-dp.yaml
```

Read the chart version from `helm list -n kong --kube-context "$PRIMARY_CONTEXT"`, then save that version:

```bash
helm pull kong/kong --version "$GATEWAY_CHART_VERSION" \
  --destination recovery/hybrid
```

Also preserve the `kong-cluster-cert` certificate and private key as `tls.crt` and `tls.key`, the license as `license.json`, and any database Secret, custom plugins, registry credentials, or externally referenced secrets. If Keyring is enabled, include its recovery private key as `keyring-recovery.pem` and confirm that recovery was configured before this backup.

Keep all of these files in protected storage outside the original environment. Record the exact Gateway image; recovery must not silently select a newer image.

## Restore the database before starting Kong

Isolate the former database writer and pause configuration pipelines. During a drill, keep the recovery database isolated from production management tools. Do not let two independent control planes accept changes intended for one authoritative environment.

Restore into the empty recovery database:

```bash
pg_restore --host="$RECOVERY_PG_HOST" --username=kong --dbname=kong \
  --exit-on-error recovery/hybrid/kong.dump
```

Expect the command to exit successfully without restore errors. This restores the schema and data together. Do not bootstrap Kong into the empty database before this restore. If it fails partway through, recreate an empty recovery database before retrying; do not accept a partial restore. See the [PostgreSQL restore reference](https://www.postgresql.org/docs/current/app-pgrestore.html).

In a copy of `values-cp.yaml`, set `env.pg_host` to the recovery database endpoint and verify the database name, role, password or Secret reference, and TLS settings. Keep the saved Gateway image unchanged.

Disable migration jobs for this same-version restore:

```yaml
migrations:
  init: false
  preUpgrade: false
  postUpgrade: false
```

Save this override as `recovery/hybrid/restore-values.yaml`. Verify that the saved chart supports these settings. The [Kong chart migration template](https://github.com/Kong/charts/blob/main/charts/kong/templates/migrations.yaml) uses `migrations.init` to control the install-time bootstrap job.

## Restore credentials and the control plane

Confirm that `RECOVERY_CONTEXT` points to the replacement cluster, then create its namespace:

```bash
kubectl --context "$RECOVERY_CONTEXT" create namespace kong
```

Restore the cluster certificate:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong create secret tls kong-cluster-cert \
  --cert=recovery/hybrid/tls.crt --key=recovery/hybrid/tls.key
```

Restore the license Secret used by the installation example:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong create secret generic kong-enterprise-license \
  --from-file=license=recovery/hybrid/license.json
```

Restore any other Secrets referenced by the saved values before installing. Deploy the control plane:

```bash
helm install kong-cp "recovery/hybrid/kong-${GATEWAY_CHART_VERSION}.tgz" \
  --kube-context "$RECOVERY_CONTEXT" -n kong \
  -f recovery/hybrid/values-cp.yaml -f recovery/hybrid/restore-values.yaml \
  --wait --timeout 5m
```

If startup fails, inspect the control plane logs for database authentication, TLS, schema, or keyring errors. Do not run migrations to work around a mismatch between the saved database and Gateway image.

Forward the private Admin API in a separate terminal:

```bash
kubectl --context "$RECOVERY_CONTEXT" -n kong port-forward \
  service/kong-cp-kong-admin 8001:8001
```

Read the Route from the restored database:

```bash
curl --fail-with-body -H "Kong-Admin-Token: $KONG_ADMIN_TOKEN" \
  http://localhost:8001/routes/dr-check
```

Expect the saved Route, including its ID and `/dr-check` path. For a different Workspace, use that Workspace's Admin API path. The local HTTP port forward follows the installation example; use your deployment's private TLS endpoint if HTTP is disabled.

### Recover Keyring, if enabled

Submit the recovery private key:

```bash
curl --fail-with-body -X POST \
  -H "Kong-Admin-Token: $KONG_ADMIN_TOKEN" \
  -F recovery_private_key=@recovery/hybrid/keyring-recovery.pem \
  http://localhost:8001/keyring/recover
```

Inspect the recovered and failed keys. Set `KEY_ID` to the recovered key to activate, then activate it:

```bash
curl --fail-with-body -X POST \
  -H "Kong-Admin-Token: $KONG_ADMIN_TOKEN" \
  --data-urlencode "key=$KEY_ID" http://localhost:8001/keyring/activate
```

Validate a request that uses encrypted configuration. A restored Route alone does not prove that encrypted credentials are usable. See [Keyring recovery](/gateway/keyring/#disaster-recovery) for the required preparation.

## Restore and test the data plane

The original data plane values reference the `kong-cp` Services in namespace `kong`. Keeping those names allows the replacement data plane to find the new control plane. If you used external control plane names, update those endpoints and their trust settings in `values-dp.yaml`.

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

Set `RECOVERY_ADDRESS` to the external address and request the saved Route:

```bash
curl --fail-with-body "http://${RECOVERY_ADDRESS}/dr-check"
```

Expect the same application result recorded before the backup. Adapt this request to the Route's hostname, TLS, and authentication requirements. A `404` indicates that the expected Route is not loaded or matched; inspect control plane synchronization before moving traffic.

Add a temporary `/dr-check-recovered` path to the Route through your normal configuration workflow. Confirm that it works on the replacement data plane, then remove it. This verifies that the recovered control plane can distribute new configuration.

## Move traffic and fail back

Update the application's DNS record or external load balancer target to the validated proxy address, then repeat the baseline requests through the normal client endpoint.

Treat the recovered database as authoritative. To fail back, synchronize the original database from that state through your PostgreSQL recovery procedure, switch the control plane to the accepted writer, validate the original data planes, and return traffic. Do not reconnect the old independently writable database as though changes will merge.

Record the backup time, missing configuration changes, successful encrypted-credential checks, and the separate traffic and configuration recovery times in the [drill record](/gateway/disaster-recovery/kubernetes/test/#record-the-results).
