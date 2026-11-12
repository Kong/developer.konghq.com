---
title: "Recover a self-managed hybrid deployment on Kubernetes"
description: "Learn what to save to recover a self-managed Kong Gateway hybrid deployment on Kubernetes, how to restore its PostgreSQL database and Keyring, and how to fail back."
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

In a self-managed [hybrid mode](/gateway/hybrid-mode/) deployment, the control plane stores the {{site.base_gateway}} configuration in PostgreSQL.
When you lose the cluster and its database, you restore the database from a backup, start a control plane on top of it, and connect replacement data planes.
The result is a new control plane that serves the configuration from the backup.
Changes that you made after the backup aren't recovered.

{:.success}
> To run the full procedure end to end in a local cluster, see [Recover a self-managed hybrid {{site.base_gateway}} deployment after a Kubernetes cluster loss](/how-to/recover-hybrid-deployment-after-cluster-loss/).

## What to save

Save the following items while the original deployment works, and keep them in protected storage outside the original environment:

{% table %}
columns:
  - title: Item
    key: item
  - title: Why you need it
    key: why
rows:
  - item: A complete `pg_dump` backup of the {{site.base_gateway}} database, in the custom format
    why: Holds the configuration. The backup contains the database only, not the PostgreSQL roles, cloud resources, or certificate files. Record its creation time and the last configuration change that it includes.
  - item: "Helm values of the `kong-cp` and `kong-dp` releases, and the chart archive"
    why: Lets you install the same chart version with the same settings.
  - item: The exact {{site.base_gateway}} image
    why: The restored database matches the schema of that version. A newer image can require migrations.
  - item: Cluster certificate and key
    why: The data planes and the control plane authenticate each other with this pair.
  - item: License and database credentials
    why: The license Secret, and the database Secret or password that the control plane values reference.
  - item: Other dependencies
    why: Custom plugins, registry credentials, and externally referenced Secrets.
  - item: Keyring recovery material
    why: "If [Keyring](/gateway/keyring/) is enabled, the recovery private key, and the Secret that mounts the public key named by `keyring_recovery_public_key`. Configure Keyring recovery before you take the backup."
{% endtable %}

Use PostgreSQL clients that are compatible with the source server.
If you run `pg_dump` from a workstation, supply database credentials through a protected PostgreSQL password file, and keep the TLS settings that your database requires.

## Restore the database

Isolate the former database writer and pause configuration pipelines before you restore.
Don't let two independent control planes accept changes that are meant for one authoritative environment.

Restore the backup into an empty database, with `pg_restore --exit-on-error`, before you start {{site.base_gateway}}:

* Don't bootstrap {{site.base_gateway}} into the empty database before the restore. The backup restores the schema and the data together.
* If the restore fails partway through, recreate an empty database before you try again. Don't accept a partial restore.

For more information, see the [PostgreSQL restore reference](https://www.postgresql.org/docs/current/app-pgrestore.html).

When you restore with the same {{site.base_gateway}} version, turn off the chart's migration jobs with an override file, and pass it after the saved values:

```yaml
migrations:
  init: false
  preUpgrade: false
  postUpgrade: false
```

The [Kong chart migration template](https://github.com/Kong/charts/blob/main/charts/kong/templates/migrations.yaml) uses `migrations.init` to control the bootstrap job that runs at install time.
Don't run migrations to work around a mismatch between the saved database and the {{site.base_gateway}} image.

If the recovery database has a different endpoint, add `env.pg_host` to the same override file.
If the database name, role, password or Secret reference, or TLS settings are also different, override them there too.
Keep the saved values file unchanged, because the values in the override take precedence.

If the control plane trusts the CA of the database server, the recovery database can present a certificate from a new CA.
For example, the CloudNativePG operator creates a new self-signed CA for every new cluster.
In that case, update the CA Secret that the control plane mounts before you start it.

If the control plane doesn't start, inspect its logs for database authentication, TLS, schema, or Keyring errors.

## Recover Keyring

If Keyring is enabled, the restored database contains the encrypted Keyring material, but the new control plane starts with an empty Keyring.
Until you recover the Keyring, Admin API reads of encrypted entities fail with HTTP `500`.

Submit the recovery private key:

```bash
curl --fail-with-body -X POST \
  -H "Kong-Admin-Token: $KONG_ADMIN_TOKEN" \
  -F recovery_private_key=@recovery/keyring-recovery.pem \
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

## Reconnect data planes

The saved data plane values reference the control plane Services by name.
If you restore the control plane with the same release name and namespace, the replacement data planes find it without changes.
If you used external control plane names, update those endpoints and their trust settings in the data plane values.

If a request through the replacement data plane fails, check the status code:

* `404`: The expected Route isn't loaded or doesn't match. Inspect control plane synchronization before you move traffic.
* `426`: The Route accepts only HTTPS. New Routes accept only HTTPS unless you set `protocols`.

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
