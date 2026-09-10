---
title: Kong worker processes exited on signal 9
content_type: support
description: This issue can be caused when Kong config parameter `nginx_worker_processes` is set to `auto`, which means it depends on the amount of cores of your nodes.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why are Kong worker processes exiting on signal 9 under high load?
  a: |
    `nginx_worker_processes` set to `auto` spawns one worker per host vCPU, which is often more workers than needed and can lead to instability under load.
    Reduce the worker count to a smaller fixed number (for example, 2 or 4) and scale horizontally to handle additional traffic, and consider increasing the memory assigned to the Kong pods.
---

## Problem

You found that worker processes in Kong are exiting on signal 9. This seems to be happening when there is a high load on Kong. The log messages are similar to:[notice] 1#0: signal 17 (SIGCHLD) received from 2420[alert] 1#0: worker process 2420 exited on signal 9[notice] 1#0: start worker process 2428[notice] 1#0: signal 29 (SIGIO) received[warn] 2428#0: found and cleared 1 stale readers from LMDB[notice] 1#0: signal 17 (SIGCHLD) received from 2421[alert] 1#0: worker process 2421 exited on signal 9[notice] 1#0: start worker process 2429[notice] 1#0: signal 29 (SIGIO) received[warn] 2429#0: found and cleared 1 stale readers from LMDB[notice] 1#0: signal 17 (SIGCHLD) received from 2422[alert] 1#0: worker process 2422 exited on signal 9[notice] 1#0: start worker process 2430[notice] 1#0: signal 29 (SIGIO) received

## Cause

This issue can be caused when Kong config parameter `nginx_worker_processes` is set to `auto`, which means it depends on the amount of cores of your nodes. If you have 8 cores, you are using 8 workers. It could happen that not all of those 8 workers are closing, only one of them closes, especially during load.

## Solution

Having as many Nginx worker processes as the underlying host has vCPUs is typically too many. You can try reducing this to a number that better resembles the assigned resources. For example you can start setting the number of workers to something small like 2 or 4, and horizontal scaling to deal with additional traffic. This may already help with memory as every worker requires some memory although things like cache are shared but it may also be worth increasing the memory assigned to the Kong pods, and checking if that prevents the issue from happening.Related documentation: Cluster resource allocations
