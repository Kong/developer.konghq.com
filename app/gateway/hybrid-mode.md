---
title: "Hybrid mode"
content_type: reference
layout: reference

products:
    - gateway

works_on:
    - on-prem
    - konnect

tags:
    - hybrid-mode
    - deployment-topologies

no_version: true

breadcrumbs:
    - /gateway

description: "Hybrid mode is a deployment model that splits all {{site.base_gateway}} nodes in a cluster into Control Planes and Data Plane nodes."

related_resources:
  - text: Deployment Topologies
    url: /gateway/deployment-topologies/
  - text: Data Plane hosting options
    url: /gateway/topology-hosting-options/
  - text: "{{site.base_gateway}} deployment models"
    url: /gateway/deployment-models/
  - text: DB-less mode
    url: /gateway/db-less-mode/
  - text: Traditional mode
    url: /gateway/traditional-mode/
---

Hybrid mode, also known as Control Plane/Data Plane separation (CP/DP), is a deployment model that splits all {{site.base_gateway}} nodes in a cluster into one of two roles: 
* Control Plane (CP) nodes, where configuration is managed and the Admin API is served from
* Data Plane (DP) nodes, which serve traffic for the proxy

In hybrid mode, the database only needs to exist on Control Plane nodes. 

Each DP node is connected to one of the CP nodes, and only the CP nodes are directly connected to a database. 
Instead of accessing the database contents directly, the DP nodes maintain a connection with CP nodes to receive the latest configuration.

{{site.konnect_short_name}} runs in hybrid mode. In this case, Kong manages the database for you, so you can't access it directly.
This means you can't manage {{site.konnect_short_name}} configuration via [`kong.conf`](/gateway/configuration/) like you can for {{site.base_gateway}}, as Kong handles that configuration. 
Additionally, {{site.konnect_short_name}} uses the [Control Plane Config API](/api/konnect/control-planes-config/v2/) to manage Control Planes while {{site.base_gateway}} uses the [Admin API](/api/gateway/admin-ee/).

The following diagram shows what {{site.base_gateway}} looks like in self-managed hybrid mode:

<!--vale off -->
{% mermaid %}
flowchart TD

A[(Database)]
B(<img src="/assets/icons/kogo-white.svg" style="max-height:20px" class="no-image-expand"/> Control plane \n #40;{{site.base_gateway}} instance#41;)
C(<img src="/assets/icons/KogoBlue.svg" style="max-height:20px" class="no-image-expand"/> Data plane 3\n #40;{{site.base_gateway}} instance#41;)
D(<img src="/assets/icons/KogoBlue.svg" style="max-height:20px" class="no-image-expand"/> Data plane 1\n #40;{{site.base_gateway}} instance#41;)
E(<img src="/assets/icons/KogoBlue.svg" style="max-height:20px" class="no-image-expand"/> Data plane 2\n #40;{{site.base_gateway}} instance#41;)

subgraph id1 [Self-managed Control Plane node]
A---B
end

B --Kong proxy 
configuration---> id2 & id3

subgraph id2 [Self-managed on-premise node]
C
end

subgraph id3 [Self-managed cloud nodes]
D
E
end

style id1 stroke-dasharray:3,rx:10,ry:10
style id2 stroke-dasharray:3,rx:10,ry:10
style id3 stroke-dasharray:3,rx:10,ry:10
style B stroke:none,fill:#0E44A2,color:#fff

{% endmermaid %}
<!-- vale on-->

> _Figure 1: In self-managed hybrid mode, the Control Plane and Data Planes are hosted on different nodes. 
The Control Plane connects to the database, and the Data Planes receive configuration from the Control Plane._

When you create a new Data Plane node, it establishes a connection to the
Control Plane. The Control Plane listens on port [`8005` ({{site.base_gateway}})](/gateway/network-ports-firewall/) or [`443` ({{site.konnect_short_name}})](/konnect-network/) for connections and
tracks any incoming data from its Data Planes.

Once connected, every API or Kong Manager/{{site.konnect_short_name}} UI action on the Control Plane
triggers an update to the Data Planes in the cluster.

## Benefits

Hybrid mode deployments have the following benefits:

* **Deployment flexibility:** Users can deploy groups of Data Planes in
different data centers, geographies, or zones without needing a local clustered
database for each DP group.
* **Increased reliability:** The availability of the database doesn't affect
the availability of the Data Planes. Each DP caches the latest configuration it
received from the Control Plane on local disk storage, so if [CP nodes are down](/gateway/cp-outage/),
the DP nodes keep functioning.  
    * While the CP is down, DP nodes constantly try to reestablish communication.
    * DP nodes can be restarted while the CP is down, and still proxy traffic
    normally.
* **Traffic reduction:** Drastically reduces the amount of traffic to and from
the database, since only CP nodes need a direct connection to the database.
* **Increased security:** If one of the DP nodes is compromised, an attacker
won’t be able to affect other nodes in the {{site.base_gateway}} cluster.
* **Ease of management:** Admins only need to interact with the CP nodes to
control and monitor the status of the entire {{site.base_gateway}} cluster.

## Platform compatibility

You can run {{site.base_gateway}} in hybrid mode on any platform where
{{site.base_gateway}} is [supported](/install/), including [{{site.konnect_short_name}}](https://cloud.konghq.com/).

## Hybrid mode with Kubernetes 

You can run {{site.base_gateway}} on Kubernetes in hybrid mode with or without the [{{site.kic_product_name}}]((/kubernetes-ingress-controller/). This uses Kubernetes as a runtime for your data planes.

Running {{site.base_gateway}} in hybrid mode is commonly referred to as "Kong _on_ Kubernetes". Running {{site.base_gateway}} with {{ site.kic_product_name }} is commonly referred to as "Kong _for_ Kubernetes", as it provides a Kubernetes native way of configuring Kong entities using {{ site.kic_product_name }}. Configuring Kong on Kubernetes is identical to deploying {{site.base_gateway}} running on a virtual machine or bare metal.

Configuring a hybrid mode deployment with {{ site.kic_product_name }} should only be used in a small set of circumstances. We recommend using hybrid mode *without* {{ site.kic_product_name }}, or [DB-less mode](/gateway/db-less-mode/) with {{ site.kic_product_name }}, unless you've been otherwise advised by a member of the Kong team.

For the full Kubernetes hybrid mode documentation, see
[hybrid mode](https://github.com/Kong/charts/blob/main/charts/kong/README.md#hybrid-mode)
in the `kong/charts` repository.

## Version compatibility

Depending on where you're running hybrid mode, the following CP/DP versioning compatibility applies:

* **Kong-managed in {{site.konnect_short_name}}:** Control planes only allow connections from Data Planes with the exact same version of the Control Plane.
* **Self-managed in {{site.base_gateway}}:** Control planes only allow connections from Data Planes with the same major version. Control planes won't allow connections from Data Planes with newer minor versions.

For example, a {{site.base_gateway}} v3.9.0.1 Control Plane:

{% feature_table %}
item_title: "Data Plane versions"
columns:
  - title: Accepted?
    key: accepted
  - title: Reason
    key: reason

features:
  - title: 3.9.0.0 and 3.9.0.1
    accepted: true
    reason: N/A
  - title: 3.8.1.0, 3.7.1.4, and 3.7.0.0
    accepted: true
    reason: N/A
  - title: 3.9.1.0
    accepted: true
    reason: Newer patch version on the Data Plane is accepted
  - title: 2.8.0.0
    accepted: false
    reason: Major version differs
  - title: 3.10.0.0
    accepted: false
    reason: Minor version on Data Plane is newer
{% endfeature_table %}

### Plugin version compatibility

For every plugin that is configured on the
Control Plane, new configs are only pushed to Data Planes that have those configured
plugins installed and loaded. The major version of those configured plugins must
be the same on both the Control Planes and Data Planes. Also, the minor versions
of the plugins on the Data Planes can't be newer than versions installed on the
Control Planes. Similar to {{site.base_gateway}} version checks,
plugin patch versions are also ignored when determining compatibility.

For instance, a new version of {{site.base_gateway}} includes a new
plugin offering, and you update your Control Plane with that version. You can
still send configurations to your Data Planes that are on a less recent version
as long as you haven't added the new plugin offering to your configuration.
If you add the new plugin to your configuration, you will need to update your
Data Planes to the newer version for the Data Planes to continue to read from
the Control Plane.

If the compatibility checks fail, the Control Plane stops
pushing out new config to the incompatible Data Planes to avoid breaking them. For more information, see [Version Compatibility in Control Planes](/gateway/cp-version-compatibility/).

If a config can not be pushed to a Data Plane due to failure of the
compatibility checks, the Control Plane will contain `warn` level lines in the
`error.log` similar to the following:

```bash
unable to send updated configuration to DP node with hostname: localhost.localdomain ip: 127.0.0.1 reason: version mismatches, CP version: 2.2 DP version: 2.1
unable to send updated configuration to DP node with hostname: localhost.localdomain ip: 127.0.0.1 reason: CP and DP does not have same set of plugins installed or their versions might differ
```

The following API endpoints return the version of the Data Plane node and the latest config hash the node is using:
* On-prem {{site.base_gateway}}: [`/clustering/data-planes` Admin API](/api/gateway/admin-ee/#/operations/getDataPlanes)
* {{site.konnect_short_name}}:  [`/expected-config-hash` Control Plane Config API](/api/konnect/control-planes-config/v2/#/operations/get-expected-config-hash) 
This data helps detect version incompatibilities from the Control Plane side.

## Fault tolerance

If Control Plane nodes are down, the Data Plane will keep functioning. Data plane caches
the latest configuration it received from the Control Plane on the local disk.
In case the Control Plane stops working, the Data Plane will keep serving requests using
cached configurations. It does so while constantly trying to reestablish communication
with the Control Plane.

This means that the Control Plane nodes can be stopped even for extended periods
of time, and the Data Plane will still proxy traffic normally. Data plane
nodes can be restarted while in disconnected mode, and will load the last
configuration in the cache to start working. When the Control Plane is brought
up again, the Data Plane nodes will contact them and resume connected mode.

You can also [configure Data Plane resiliency](/gateway/cp-outage/) in case of Control Plane outages. 

### Disconnected mode in on-prem deployments

The viability of the Data Plane while disconnected means that Control Plane
updates or database restores can be done with peace of mind. First bring down
the Control Plane, perform all required downtime processes, and only bring up
the Control Plane after verifying the success and correctness of the procedure.
During that time, the Data Plane will keep working with the latest configuration.

A new Data Plane node can be provisioned during Control Plane downtime. This
requires either copying the LMDB directory (`dbless.lmdb`) from another
Data Plane node, or using a declarative configuration. In either case, if it
has the role of `"data_plane"`, it will also keep trying to contact the control
plane until it's up again.

To change a disconnected Data Plane node's configuration in self-managed hybrid mode, you must:
* Remove the LMDB directory (`dbless.lmdb`)
* Ensure the [`declarative_config`](/gateway/configuration/#declarative_config) parameter or the `KONG_DECLARATIVE_CONFIG` environment variable is set
* Set the whole configuration in the referenced YAML file

### Data plane cache configuration

By default, Data Planes store their configuration to the file system
in an unencrypted LMDB database, `dbless.lmdb`, in {{site.base_gateway}}'s
[`prefix` path](/gateway/configuration/#prefix). You can also choose to encrypt this database.

If encrypted, the Data Plane uses the cluster certificate key to decrypt the
LMDB database on startup.

## Limitations

### Configuration inflexibility

In {{site.base_gateway}} 3.9.x or earlier, whenever you make changes to {{site.base_gateway}} entity configuration on the Control Plane, it immediately triggers a cluster-wide update of all Data Plane configurations. This can cause performance issues.

You can enable **incremental configuration sync** for improved performance in {{site.base_gateway}} 3.10.x or later. 
When a configuration changes, instead of sending the entire configuration set for each change, {{site.base_gateway}} only sends the parts of the configuration that have changed. 

See the [incremental configuration sync](/gateway/incremental-config-sync/) documentation to learn more.

### Plugin incompatibility

When plugins are running on a Data Plane in hybrid mode, there is no API
exposed directly from that DP. Since the Admin API is only exposed from the
Control Plane, all plugin configuration has to occur from the CP. Due to this
setup, and the configuration sync format between the CP and the DP, some plugins
have limitations in hybrid mode:

* [**Key Auth Encrypted**](/plugins/key-auth-enc/): The time-to-live setting
(`ttl`), which determines the length of time a credential remains valid, does
not work in hybrid mode.
* [**Rate Limiting**](/plugins/rate-limiting/), [**Rate Limiting Advanced**](/plugins/rate-limiting-advanced/), [**Response Rate Limiting**](/plugins/response-ratelimiting/), [AI Rate Limiting Advanced](/plugins/ai-rate-limiting-advanced/), and [Service Protection](/plugins/service-protection/):
These plugins don't support the `cluster` strategy/policy in hybrid mode. One of 
the `local` or `redis` strategies/policies must be used instead.
* [**GraphQL Rate Limiting Advanced**](/plugins/graphql-rate-limiting-advanced/):
This plugin doesn't support the `cluster` strategy in hybrid mode. The `redis` 
strategy must be used instead.
* [**OAuth 2.0 Authentication**](/plugins/oauth2/): This plugin is not
compatible with hybrid mode. For its regular workflow, the plugin needs to both
generate and delete tokens, and commit those changes to the database, which is
not possible with CP/DP separation.

### Custom plugins

Custom plugins (either your own plugins or third-party plugins that are not
shipped with {{site.base_gateway}}) need to be installed on both the Control Plane and the data
plane in hybrid mode.

### Consumer groups
The ability to scope plugins to consumer groups was added in {{site.base_gateway}} version 3.4. Running a mixed-version {{site.base_gateway}} cluster (3.4 Control Plane, and <=3.3 Data Planes) is not supported when using consumer group scoped plugins. 

### Load balancing

There is no automated load balancing for connections between the
Control Plane and the Data Plane. You can load balance manually by using
multiple Control Planes and redirecting the traffic using a TCP proxy.

## Read-only Status API endpoints on Data Plane

Several read-only endpoints from the Admin API
are exposed to the [Status API](/gateway/configuration/#status_listen) on Data Planes, including the following:

- `GET /upstreams/{upstream}/targets/`
- `GET /upstreams/{upstream}/health/`
- `GET /upstreams/{upstream}/targets/all/`
- `GET /upstreams/{upstream}/targets/{target}`

See Upstream objects in the [Admin API](/api/gateway/admin-ee/#/operations/list-upstream) and [Control Plane Config API](/api/konnect/control-planes-config/v2/#/operations/list-upstream) documentation for more information about the
endpoints.

## Keyring encryption in hybrid mode

Because the [Keyring](/gateway/keyring/) module encrypts data in the database, it can't encrypt
data on Data Plane nodes, since these nodes run without a database and get
data from the Control Plane.
