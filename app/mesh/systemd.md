---
title: Systemd
content_type: reference
layout: reference
description: "Configure systemd unit files to manage the control plane and data plane proxy processes on VMs."
products:
  - mesh
breadcrumbs:
  - /mesh/
tags:
  - control-plane
  - data-plane
  - universal-mode
---

We recommend using a process manager like [systemd](https://systemd.io/) when running {{ site.mesh_product_name }} on VMs, because it restarts the control plane and data plane proxy processes automatically after failures or reboots.

The following examples show systemd unit files for the control plane (`kuma-cp`) and the data plane proxy (`kuma-dp`).

## Control plane (`kuma-cp`)

The following unit file runs `kuma-cp` as a long-running service. The `[Service]` section sets the user and working directory, then starts the control plane with a config file. `Restart = always` and `RestartSec = 1s` make systemd restart the process one second after any exit.

If your control plane needs to handle a non-trivial number of concurrent connections (a total of both incoming and outgoing connections), set proper resource limits on the `kuma-cp` process, especially the maximum number of open files. `systemd` units aren't affected by the traditional `ulimit` configuration, so you must set resource limits as part of the `systemd` unit itself. To check effective resource limits on a running `kuma-cp` instance, run:

```bash
cat /proc/$(pgrep kuma-cp)/limits
```

The example below sets `LimitNOFILE` to `1048576`, the same limit that `docker` and `containerd` [set by default](https://github.com/containerd/containerd/issues/3201).

`StartLimitIntervalSec = 0` and `StartLimitBurst = 0` disable rate limiting on start attempts, so systemd keeps trying to restart the control plane regardless of how often it has failed recently.

```
[Unit]
Description = {{ site.mesh_product_name }} Control Plane
After = network.target
Documentation = https://developer.konghq.com/mesh/

[Service]
User = USER_NAME
WorkingDirectory = MESH_INSTALL_DIRECTORY
ExecStart = ./bin/kuma-cp run --config-file=./cp-config.yaml
LimitNOFILE = 1048576
Restart = always
RestartSec = 1s
StartLimitIntervalSec = 0
StartLimitBurst = 0

[Install]
WantedBy = multi-user.target
```

## Data plane proxy (`kuma-dp`)

The following unit file runs `kuma-dp` as a long-running service. The `ExecStart` command points the data plane proxy at the control plane address and supplies the dataplane token, dataplane definition, and CA certificate. `Restart = always` and `RestartSec = 1s` make systemd restart the proxy one second after any exit, and `StartLimitIntervalSec = 0` and `StartLimitBurst = 0` disable rate limiting on start attempts so systemd keeps retrying after repeated failures.

```
[Unit]
Description = {{ site.mesh_product_name }} Data Plane Proxy
After = network.target
Documentation = https://developer.konghq.com/mesh/

[Service]
User = USER_NAME
WorkingDirectory = MESH_INSTALL_DIRECTORY
ExecStart = ./bin/kuma-dp run \
  --cp-address=https://CP_ADDRESS:5678 \
  --dataplane-token-file=./echo-service-universal.token \
  --dataplane-file=./dataplane-notransparent.yaml \
  --ca-cert-file=./ca.pem
Restart = always
RestartSec = 1s
StartLimitIntervalSec = 0
StartLimitBurst = 0

[Install]
WantedBy = multi-user.target
```
