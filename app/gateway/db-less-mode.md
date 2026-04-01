---
title: "DB-less mode"

content_type: reference
layout: reference

products:
    - gateway

works_on:
    - on-prem

tags:
    - deployment-topologies

no_version: true

breadcrumbs:
  - /gateway/

description: "Explains how {{site.base_gateway}} can be run without a database using only in-memory storage for entities."

related_resources:
  - text: Deployment topologies
    url: /gateway/deployment-topologies/
  - text: Data Plane hosting options
    url: /gateway/topology-hosting-options/
  - text: Hybrid mode
    url: /gateway/hybrid-mode/
  - text: Traditional mode
    url: /gateway/traditional-mode/
  - text: "CLI reference: kong config"
    url: /gateway/cli/reference/#kong-config
  - text: "{{site.base_gateway}} entity references"
    url: /gateway/entities/
---

{{site.base_gateway}} can be run without a database using only in-memory storage for [entities](/gateway/entities/). 
We call this DB-less mode. When running {{site.base_gateway}} DB-less, the configuration of 
entities is done in a second configuration file, in YAML or JSON, using declarative configuration.

The combination of DB-less mode and declarative configuration has a number
of benefits:

* Reduced number of dependencies: No need to manage a database installation
  if the entire setup for your use-cases fits in memory.
* Automation in CI/CD scenarios: Configuration for
  entities can be kept in a single source of truth managed via a Git
  repository.
* Enables more deployment options for {{site.base_gateway}}.

{:.warning}
> **Important**: [decK](/deck/) also manages configuration declaratively, but it requires
a database to perform any of its sync, dump, or similar operations. Therefore, decK 
can't be used in DB-less mode.

<!--vale off -->
{% mermaid %}
flowchart TD

A(<img src="/assets/icons/gateway.svg" style="max-height:20px" class="no-image-expand"/> {{site.base_gateway}} instance)
B(<img src="/assets/icons/gateway.svg" style="max-height:20px" class="no-image-expand"/> {{site.base_gateway}} instance)
C(<img src="/assets/icons/gateway.svg" style="max-height:20px" class="no-image-expand"/> {{site.base_gateway}} instance)

A2(fa:fa-file kong1.yml)
B2(fa:fa-file kong1.yml)
C2(fa:fa-file kong1.yml)

A2 --> A
B2 --> B
C2 --> C

{% endmermaid %}
<!-- vale on-->


## How declarative configuration works in DB-less mode

The key idea in declarative configuration is the notion
that it is *declarative*, as opposed to an *imperative* style of
configuration. Imperative means that a configuration is given as a series of
orders. Declarative means that the configuration is
given all at once.

The [Admin API](/api/gateway/admin-ee/) is an example of an imperative configuration tool. The
final state of the configuration is attained through a sequence of API calls:
one call to create a Service, another call to create a Route, another call to
add a plugin, and so on.

Incremental configuration like this has the undesirable
side-effect that *intermediate states* happen. In the above example, there is
a window of time in between creating a Route and adding the plugin in which
the Route didn't have the plugin applied.

A declarative configuration file, on the other hand, contains the settings
for all needed [entities](/gateway/entities/) in a single file. Once that file is loaded into
{{site.base_gateway}}, it replaces the entire configuration. When incremental changes are
needed, they are made to the declarative configuration file, which is then
reloaded in its entirety. At all times, the configuration described in the
file loaded into {{site.base_gateway}} is the configured state of the system.

## Set up {{site.base_gateway}} in DB-less mode

To use {{site.base_gateway}} in DB-less mode, set the [`database` directive of `kong.conf`](/gateway/configuration/#database) to `off`. You can do this by editing `kong.conf` and setting
`database=off` or via environment variables (`export KONG_DATABASE=off`), and then [starting {{site.base_gateway}}](/gateway/cli/reference/#kong-start).

You can verify that {{site.base_gateway}} is deployed in DB-less mode by sending the following:
```sh
curl -i -X GET http://localhost:8001
```

This will return the entire {{site.base_gateway}} configuration. Verify that `database` is set to `off` in the response body.

## Generate a declarative configuration file

To get started using declarative configuration, you need a JSON or YAML file containing [{{site.base_gateway}} entity definitions](/gateway/entities/).

The following command generates a file named `kong.yml` in the current directory containing configuration examples:

```
kong config init
```

## Load the declarative configuration file

There are two ways to load a declarative configuration file into {{site.base_gateway}}: 
* At start-up, using `kong.conf`
* At runtime, using the [`/config` Admin API endpoint](/api/gateway/admin-ee/#/operations/post-config)

You can use the following `kong.conf` parameters to load the declarative config file:

<!--vale off-->
{% kong_config_table %}
config:
  - name: declarative_config
  - name: declarative_config_string
{% endkong_config_table %}
<!--vale on-->

## DB-less mode with Kubernetes

You can run DB-less mode with Kubernetes both with and without [{{ site.kic_product_name }}](/kubernetes-ingress-controller/).

### DB-less mode with {{ site.kic_product_name }}

{{ site.kic_product_name }} provides a Kubernetes native way to configure {{ site.base_gateway }} using custom resource definitions (CRDs). In this deployment pattern, {{ site.base_gateway }} is deployed in DB-less mode, where the Data Plane configuration is held in memory.

Operators configure {{ site.base_gateway }} using standard CRDs such as `Ingress` and `HTTPRoute`, and {{ site.kic_product_name }} translates those resources into {{site.base_gateway}} entities before sending a request to update the running Data Plane configurations.

In this topology, the Kubernetes API server is your source of truth. {{ site.kic_product_name }} reads resources stored on the API server and translates them into a valid {{site.base_gateway}} configuration object. You can think of {{ site.kic_product_name }} as the Control Plane for your DB-less Data Planes.

For more information about {{ site.base_gateway }} and {{ site.kic_product_name }}, see the {{ site.kic_product_name }} [getting started guide](/kubernetes-ingress-controller/install/). This guide walks you through installing {{ site.base_gateway }}, configuring a Service and Route, then adding a rate limiting and caching plugin to your deployment.

### DB-less with Helm ({{ site.kic_product_name }} disabled)

When deploying {{site.base_gateway}} on Kubernetes in DB-less mode (`env.database: "off"`) and without the {{ site.kic_product_name }} (`ingressController.enabled: false`), you have to provide a declarative configuration for {{site.base_gateway}} to run. You can provide an existing ConfigMap (`dblessConfig.configMap`) or place the whole configuration into a `values.yaml` (`dblessConfig.config`) parameter. See the example configuration in the [default `values.yaml`](https://github.com/kong/charts/blob/main/charts/kong/values.yaml) for more detail.

Use `--set-file dblessConfig.config=/path/to/declarative-config.yaml` in Helm commands to substitute in a complete declarative config file.

Externally supplied ConfigMaps aren't hashed or tracked in deployment annotations. Subsequent ConfigMap updates require user-initiated deployment rollouts to apply the new configuration. Run `kubectl rollout restart deploy` after updating externally supplied ConfigMap content.

## DB-less mode limitations

There are a number of limitations you should be aware of when using {{site.base_gateway}} in DB-less
mode.

### Memory cache requirements

The entire configuration of entities must fit inside the {{site.base_gateway}}
cache. Make sure that the in-memory cache is configured appropriately in [`kong.conf`](/gateway/manage-kong-conf/):

<!--vale off-->
{% kong_config_table %}
config:
  - name: mem_cache_size
{% endkong_config_table %}
<!--vale on-->

### No central database coordination

Since there is no central database, {{site.base_gateway}} nodes have no
central coordination point and no cluster propagation of data.
Nodes are completely independent of each other.

This means that the declarative configuration should be loaded into each node
independently. Using the [`/config` endpoint](/api/gateway/admin-ee/#/operations/get-config) doesn't affect other {{site.base_gateway}}
nodes, since they have no knowledge of each other.

### Read-only Admin API

Since the only way to configure entities is via declarative configuration,
the endpoints for CRUD operations on entities are effectively read-only
in the [Admin API](/api/gateway/admin-ee/) when running {{site.base_gateway}} in DB-less mode. `GET` operations
for inspecting entities work as usual, but attempts to `POST`, `PATCH`
`PUT` or `DELETE` in endpoints such as `/services` or `/plugins` will return
`HTTP 405 Not Allowed`.

This restriction is limited to what would otherwise be database operations. In
particular, using `POST` to set the health state of targets is still enabled,
since this is a node-specific in-memory operation.

### Kong Manager compatibility

[Kong Manager](/gateway/kong-manager/) cannot guarantee compatibility with {{site.base_gateway}} operating in DB-less mode. You cannot create, update, or delete entities with Kong Manager when {{site.base_gateway}} is running in this mode. Entity counters in the **Summary** section on the global and workspace overview pages will not function correctly either.

### Plugin compatibility

Not all {{site.base_gateway}} plugins are compatible with DB-less mode. By design, some plugins
require central database coordination or dynamic creation of
entities.

For current plugin compatibility, see [Plugins](/gateway/entities/plugin/).
