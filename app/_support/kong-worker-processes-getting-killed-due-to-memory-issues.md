---
title: kong worker processes getting killed due to memory issues (after moving to a new host)
content_type: support
description: A common reason why the OOMKiller may kick in on a kong node is due to the configuration of the number of worker processes in kong.
products:
  - gateway
  - kic
works_on:
  - on-prem
  - konnect
related_resources:
  - text: the configuration option for the workers
    url: /gateway/configuration/#nginx-worker-processes
tldr:
  q: Why are Kong worker processes getting killed due to memory issues (OOMKilled)?
  a: |
    Kong's default `nginx_worker_processes` setting of `auto` starts one worker process per host vCPU, which can use more memory than the host has available — especially after moving to a smaller host — triggering the OOM killer (SIGCHLD, OOMKilled).
    Set `nginx_worker_processes` to a fixed, smaller number (2 or 4 is often enough) instead of `auto` to match your host's resources.
---

## Problem

Kong nodes are being terminated, resulting in a signal 17 (SIGCHLD) log message in the kong error log and possibly log entries like `failed while spawning "worker process" (12: Out of memory)`. When using kubernetes, the relevant pod shows a state of terminated with reason: OOMKilled.

## Cause

A common reason why the OOMKiller may kick in on a kong node is due to the configuration of the number of worker processes in kong.

## Solution

There is a configuration option for the workers that is documented here.

The default setting for this configuration option is `auto`, which means that Kong will start as many nginx worker processes as the underlying host has vCPUs. This is typically too many, and will cause an increase in memory resource utilization, as each worker has its own memory overhead. If you start seeing this issue after moving the Kong infrastructure to a new set of hosts, it is likely that this is causing the memory issue.

To address the issue, reduce this to a number of workers configured in kong to something that better resembles the assigned resources.

The current {{site.kic_product_name}} Helm chart sets `nginx_worker_processes` to 2 by default, and it is expected to use horizontal scaling to deal with additional traffic.

However, if you are using the `auto` setting, you should set the number of workers to something small like 2 or 4.

If you are using the kong Helm charts you can change the number of workers in the env section

E.g.:

`nginx_worker_processes: "2"`
