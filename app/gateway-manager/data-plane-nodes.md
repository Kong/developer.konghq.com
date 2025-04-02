---
title: "data plane nodes"
content_type: reference
layout: reference

products:
    - gateway

min_version:
    gateway: '3.5'

description: placeholder

related_resources:
  - text: "Secure {{site.base_gateway}}"
    url: /gateway/security/
  - text: "{{site.base_gateway}} logs"
    url: /gateway/logs/
  - text: "{{site.base_gateway}} debugging"
    url: /gateway/debug/

works_on:
  - on-prem
  - konnect

faqs:
  - q: How long can data plane nodes remain disconnected from the control plane?
    a: |
      Data plane nodes continue pinging the control plane until reconnected or stopped. 
      They use cached config and function normally, unless:
      * The license expires
      * The cached config file (`config.json.gz` or `dbless.lmdb`) is deleted
  - q: Can I restart a data plane node if the control plane is down or disconnected?
    a: |
      Yes. Restarting a data plane node will load its cached configuration and resume normal function.
  - q: Can I change a data plane node's configuration when it's disconnected from the control plane?
    a: |
      Yes 
      * Copy the configuration cache file or directory from a working node
      * Remove the cache and use [`declarative_config`](/gateway/configuration/#declarative-config)
  - q: If the data plane loses communication with the control plane, what happens to telemetry data?
    a: |
      The data plane buffers request data locally. If the buffer fills up (default: 100000 requests), older data is dropped.
      You can configure the buffer size using the [`analytics_buffer_size_limit`](/gateway/configuration/#analytics-buffer-size-limit) setting.
  - q: How frequently do data planes send telemetry data to the control plane?
    a: |
      Telemetry data is sent at different intervals depending on the data plane version:
      * **2.x** – Every 10 seconds by default
      * **3.x** – Every 1 second by default

      You can customize this interval using the [`analytics_flush_interval`](/gateway/configuration/#analytics_flush_interval) setting.
  - q: How do the control plane and data plane communicate?
    a: |
      Data traveling between control planes and data planes is secured through a mutual TLS handshake. 
      Data plane nodes initiate the connection to the {{site.konnect_short_name}} control plane. 
      Once the connection is established, the control plane can send configuration data to the connected data plane nodes.

      Each data plane node maintains a persistent connection with the control plane and sends a heartbeat every 30 seconds. 
      If the control plane doesn't respond, the data plane node attempts to reconnect after a 5–10 second delay.

---

@todo
https://docs.konghq.com/konnect/gateway-manager/data-plane-nodes/


still to-do but this text can go here. 
{{site.konnect_saas}} deployments run either in either [managed](/konnect/gateway-manager/dedicated-cloud-gateways) or hybrid mode, which means that there is
a separate control plane attached to a data plane consisting of one or more 
data plane nodes. Control planes and data plane nodes must communicate with 
each other to receive and send configurations. If communication is interrupted 
and either side can't send or receive config, data plane nodes can still continue 
proxying traffic to clients.

Whenever a data plane node receives new configuration from the control plane,
it immediately loads that config into memory. At the same time, it caches
the config to the file system. The location of the cache differs depending
on the major release of your Gateway:

* **2.x Gateway**: By default, data plane nodes store their configuration in an
unencrypted cache file, `config.json.gz`, in {{site.base_gateway}}’s prefix path.
* **3.x Gateway**: By default, data plane nodes store their configuration in an
unencrypted LMDB database directory, `dbless.lmdb`, in {{site.base_gateway}}’s
prefix path.
