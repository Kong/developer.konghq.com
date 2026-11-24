---
title: "Data Plane reference"
content_type: reference
layout: reference
description: | 
    Manage Data Plane nodes in {{site.konnect_short_name}}, including platform support, proxy access, version upgrades, certificate renewal, required parameters, and custom metadata labels.
products:
    - gateway
works_on:
    - konnect
api_specs:
    - konnect/control-planes-config
faqs:
  - q: How can I verify that a Data Plane node is running?
    a: |
      You can verify a Data Plane node by accessing a configured route through its proxy URL. 
      By default, {{site.base_gateway}} listens on port `8000`, so a request to `http://localhost:8000/YOUR-ROUTE` (or your custom hostname) 
      should return the expected response from your upstream service.

  - q: How do I access Services through a Data Plane node running on Kubernetes?
    a: |
      1. Run the following command to get the external IP and port:
         ```bash
         kubectl get service my-kong-kong-proxy -n kong
         ```
      2. Find the IP in the `EXTERNAL-IP` column and use it with port `80` or `443` along with your route.

         For example, if the external IP is `35.233.198.16` and your route is `/mock`, access your service at:
         ```
         http://35.233.198.16:80/mock
         ```
  - q: Can I choose a specific {{site.base_gateway}} version when using quickstart scripts?
    a: |
      Yes. {{site.konnect_short_name}} lets you select the {{site.base_gateway}} version for your quickstart scripts.

  - q: Can I SSH directly into {{site.konnect_short_name}} Data Plane nodes?
    a: |
      No. Direct SSH access is not possible because the SSH keys are randomly generated and not exposed. 
      To access nodes, use the cloud provider’s tools:
      * [AWS EC2 Instance Connect](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-connect-methods.html)
      * [Azure Cloud Shell](https://learn.microsoft.com/azure/cloud-shell/overview)
      * [Google Cloud SSH](https://cloud.google.com/compute/docs/instances/ssh)

  - q: Why is a data plane node running an older configuration than the one I published?
    a: |
      The node rejected the configuration you published, or its {{site.base_gateway}} version can't apply it. 
      Rather than leave the node without a configuration, {{site.konnect_short_name}} keeps it on the last configuration that worked for its version, and reports it as **Last known good config**. 
      Select the node on the **Data plane nodes** tab to see which configuration it rejected and why.

  - q: Does {{site.konnect_short_name}} roll back a bad configuration?
    a: |
      No. {{site.konnect_short_name}} never replaces a configuration that a data plane node is already running. 
      A node that rejects a new configuration keeps serving the one it has. 
      {{site.konnect_short_name}} only sends a stored configuration to a node that has none, and it can't detect a configuration that's applied successfully but behaves incorrectly at runtime.


related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Serverless Gateways
    url: /serverless-gateways/

tags:
  - data-plane
  - data-plane-nodes
  - gateway-manager

breadcrumbs:
  - /konnect/
---


A Data Plane node is a single instance of {{site.base_gateway}} that acts as a proxy and serves traffic.
In {{site.konnect_short_name}}, Data Plane nodes are managed by [Control Planes](/gateway/control-plane-groups/). 
Control Planes manage and store configurations in {{site.konnect_short_name}}, and they distribute those configurations to Data Planes nodes. 
Data Plane nodes don't manage their own configurations.

{{site.konnect_short_name}} provides Data Plane node installation scripts for various platforms. 
These Data Plane nodes are configured to run in your {{site.konnect_short_name}} environment. 
Alternatively, {{site.konnect_short_name}} offers fully-managed Data Planes through [Dedicated Cloud Gateways](/dedicated-cloud-gateways/).

## Supported installation options

{{site.konnect_short_name}} supports the following installation options:

{% table %}
columns:
  - title: Setup Type
    key: type
  - title: Platforms
    key: platforms
rows:
  - type: Standard setup (Docker)
    platforms: macOS (ARM), macOS (Intel), Windows, Linux
  - type: Advanced setup
    platforms: Linux, Kubernetes
{% endtable %}

## Choose a Data Plane node hosting strategy

The following table can help you decide which Data Plane node strategy to use based on your use case:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Data Plane node strategy
    key: strategy
  - title: Solution
    key: solution
rows:
  - use_case: Reducing latency is important to your organization.
    strategy: "[Dedicated Cloud Gateways](/dedicated-cloud-gateways/)"
    solution: |
      Supports [multiple regions](/konnect-platform/geos/) on AWS and Azure.
  - use_case: Your organization operates in an industry with strict data protection and privacy requirements.
    strategy: "[Dedicated Cloud Gateways](/dedicated-cloud-gateways/)"
    solution: Using the private gateway option, Kong provisions a private network load balancer and only exposes the IP address in the UI.
  - use_case: Your organization needs high availability with zero downtime when upgrading Data Plane nodes.
    strategy: "[Dedicated Cloud Gateways](/dedicated-cloud-gateways/)"
    solution: |
      There's no downtime when upgrading your Data Plane nodes. Additionally, you can pre-warm your cluster by specifying the number of requests per second so that the first requests don’t have to wait for the infrastructure to scale up.
  - use_case: You have infrastructure in multiple clouds.
    strategy: "[Dedicated Cloud Gateways](/dedicated-cloud-gateways/)"
    solution: Dedicated Cloud Gateways allows you to run a multi-cloud solution that allows you to standardize API operations across the board to reduce complexity and increase agility.
  - use_case: "You need _very_ rapid provisioning for experimentation and sandbox use cases."
    strategy: "[Serverless Gateways](/serverless-gateways/)"
    solution: "Serverless Gateways offer sub-minute provisioning times and enable rapid iteration and development lifecycles."
  - use_case: "You use a cloud provider (other than AWS or Azure) for hosting, or don't want to host in the cloud because of organizational policy."
    strategy: Self-managed
    solution: |
      You can deploy self-managed data plane nodes on macOS, Windows, Linux (Docker), or Kubernetes.
{% endtable %}
<!--vale on-->

## Forward proxy support

{{site.konnect_short_name}} supports using non-transparent forward proxies to connect your {{site.base_gateway}} Data Plane with the {{site.konnect_short_name}} Control Plane. See the [Forward proxy connections](/gateway/cp-dp-communication/) {{site.base_gateway}} documentation for more information.


## Upgrade Data Planes

Self-managed Data Plane nodes can be upgraded to a new {{site.base_gateway}} by initializing new nodes before decommissioning old ones. 
This method ensures high availability, allowing the new node to start data processing prior to the removal of the old node. 

Managed nodes are upgraded automatically after selecting the new version of {{site.base_gateway}}. 
We recommend running one major version (2.x or 3.x) of a Data Plane node per Control Plane, unless you are in the middle of version upgrades to the Data Plane. Mixing versions may cause [compatibility issues](/konnect-platform/compatibility/).

To upgrade a Data Plane node to a new version, follow these steps:

{% navtabs "Upgrade" %}
{% navtab "Dedicated Cloud Gateways" %}

Using the `control_plane_id`, `cloud_gateway_network_id`, and the desired [`version`](/konnect-platform/compatibility/), you can use the API to upgrade a Data Plane node:
<!-- vale off -->

{% control_plane_request %}
url: /v2/cloud-gateways/configurations
status_code: 201
method: PUT
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: Bearer $KONNECT_TOKEN'
body:
    control_plane_id: $CONTROL_PLANE_ID
    version: 3.10
    control_plane_geo: ap-northeast-1
    dataplane_groups:
      - provider: aws 
      - region: $REGION
      - cloud_gateway_network_id: $CLOUD_GATEWAY_NETWORK_ID
      - autoscale: 
        - kind: autopilot
        - base_rps: 100
{% endcontrol_plane_request %}

<!-- vale on -->

{{site.konnect_short_name}} performs a rolling upgrade of the fully-managed Data Plane nodes. 
This is a zero downtime upgrade because {{site.konnect_short_name}} synchronizes the Data Plane with load balancer registration and de-registration and gracefully terminates the old Data Plane nodes to reduce the impact on the ongoing traffic.

{% endnavtab %}

{% navtab "Hybrid mode" %}

1. In {{site.konnect_short_name}}, navigate to [**API Gateway**](https://cloud.konghq.com/gateway-manager/) in the {{site.konnect_short_name}} sidebar.
1. Click a control plane and provision a new data plane node.

    Make sure that your new data plane node appears in the list of nodes, 
    displays a _Connected_ status, and that it was last seen _Just Now_.

1. Once the new data plane node is connected and functioning, disconnect
and shut down the nodes you are replacing.

    {:.info}
    > You can't shut down data plane nodes from the {{site.konnect_short_name}} UI. 
    Old nodes will also remain listed as `Connected` for a few hours after they have been removed or shut down.

1. Test passing data through your new data plane node by accessing your proxy URL.

    For example, with the hostname `localhost` and the route path `/mock`:

    ```
    http://localhost:8000/mock
    ```
{% endnavtab %}
{% endnavtabs %}

## Data Plane certificates

Data Plane certificates generated by {{site.konnect_short_name}} expire every ten years. If you bring your own certificates, make sure to review the expiration date and associated metadata.

Renew your certificates to prevent any interruption in communication between
{{site.konnect_short_name}} and any configured Data Plane nodes. The following happens if a certificate expires and isn't replaced: 
* The Data Plane node stops receiving configuration updates from
the Control Plane.
* The Data Plane node stops sending [analytics](/observability/) and usage data to the Control Plane.
* Each disconnected Data Plane node uses cached configuration to continue
proxying and routing traffic.

Depending on your setup, renewing certificates might mean bringing up a new Data
Plane, or generating new certificates and updating Data Plane nodes with the new
files.

## Advanced parameter reference

The following parameters are the minimum settings required for a Data Plane node: 

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Field in {{site.konnect_short_name}}
    key: field
  - title: Description and Value
    key: description
rows:
  - parameter: "`role`"
    field: "n/a"
    description: "The role of the node, in this case `data_plane`."
  - parameter: "`database`"
    field: "n/a"
    description: "Specifies whether this node connects directly to a database. For a Data Plane, this setting is always `off`."
  - parameter: "`cluster_mtls`"
    field: "n/a"
    description: "Enables mTLS on connections between the Control Plane and the Data Plane. In this case, set to `\"pki\"`."
  - parameter: "`cluster_control_plane`"
    field: "n/a"
    description: "Sets the address of the {{site.konnect_short_name}} Control Plane. Must be in the format `host:port`, with port set to `443`.<br><br>**Example:**<br>Control Plane endpoint in {{site.konnect_short_name}}:<br>`https://example.cp.khcp.konghq.com`<br>Configuration value:<br>`example.cp.khcp.konghq.com:443`"
  - parameter: "`cluster_server_name`"
    field: "n/a"
    description: "The SNI (Server Name Indication extension) to use for Data Plane connections to the Control Plane through TLS. When not set, Data Plane will use `kong_clustering` as the SNI."
  - parameter: "`cluster_telemetry_endpoint`"
    field: "n/a"
    description: "The address that the Data Plane uses to send Analytics telemetry data to the Control Plane. Must be in the format `host:port`, with port set to `443`.<br><br>**Example:**<br>Telemetry endpoint in {{site.konnect_short_name}}:<br>`https://example.tp.khcp.konghq.com`<br>Configuration value:<br>`example.tp.khcp.konghq.com:443`"
  - parameter: "`cluster_telemetry_server_name`"
    field: "n/a"
    description: "The SNI (Server Name Indication extension) to use for Analytics telemetry data."
  - parameter: "`cluster_cert`"
    field: "**Certificate**"
    description: "The certificate used for mTLS between CP/DP nodes."
  - parameter: "`cluster_cert_key`"
    field: "**Private Key**"
    description: "The private key used for mTLS between CP/DP nodes."
  - parameter: "`lua_ssl_trusted_certificate`"
    field: "n/a"
    description: "Either a comma-separated list of paths to certificate authority (CA) files in PEM format, or `system`. We recommend using the value `system` to let {{site.konnect_short_name}} search for the default provided by each distribution."
  - parameter: "`konnect_mode`"
    field: "n/a"
    description: "Set to `on` for any Data Plane node connected to {{site.konnect_short_name}}."
  - parameter: "`vitals`"
    field: "n/a"
    description: "Legacy Vitals analytics reporting mechanism. Set to `off` for all {{site.base_gateway}} versions >= 3.0. Set to `on` for {{site.base_gateway}} 2.8.x to collect Vitals data and send it to the Control Plane for Analytics dashboards and metrics."
{% endtable %}

## Custom Data Plane labels

Labels are commonly used for metadata information. Set anything that you need to identify your Data Plane nodes -- deployment type, region, size, the team that the node belongs to, the purpose it serves, or any other identifiable information. For more information, review the [{{site.konnect_short_name}} labels](/konnect-platform/konnect-labels/) documentation.

## Data plane configuration status

Each data plane node validates the configuration the control plane sends it, and applies or rejects it on its own.
A node that's already running a configuration keeps running it if it rejects a new one, so a running fleet keeps serving traffic.

To limit that exposure, {{site.konnect_short_name}} stores the most recent configuration that a data plane node accepted, for each {{site.base_gateway}} version.
If a node without a configuration rejects the configuration it's sent, {{site.konnect_short_name}} sends it the stored configuration instead, so the node starts proxying traffic.
That node then runs an older configuration than the one you last published, and {{site.konnect_short_name}} reports it as **Last known good config**.
{{site.konnect_short_name}} enables this for all control planes, and you don't need to configure it.

A node that doesn't have a configuration yet is the exception: if it rejects the configuration it's sent, it has nothing to serve.
This happens most often to nodes that are created by an autoscaling event, a rolling deploy, or a new pod.

### How the last known good configuration works

A data plane node can reject a configuration for the following reasons:

* A version compatibility transformation fails for the node's {{site.base_gateway}} version.
* The configuration contains an entity or plugin shape that the node's {{site.base_gateway}} version doesn't support.
* A problem on the control plane side prevents the node from applying the full configuration. This doesn't include a control plane outage.

{{site.konnect_short_name}} stores and sends a last known good configuration in the following sequence:

1. A data plane node applies a configuration and reports its configuration hash to the control plane.
1. {{site.konnect_short_name}} stores that configuration as the last known good one for that control plane and {{site.base_gateway}} version.
1. A node without a configuration connects, and the control plane sends it the current configuration.
1. The node rejects that configuration and reports the error.
1. {{site.konnect_short_name}} sends the node the stored configuration for its {{site.base_gateway}} version.
1. The node applies the stored configuration and starts proxying traffic.

The node runs the stored configuration until the next configuration change.
At that point, the control plane reconciles every connected node, and any node that can apply the new configuration returns to **In sync**.

### Recovery time

Under normal conditions, a node receives the stored configuration within seconds of reporting that it rejected the current one.
{{site.konnect_short_name}} allows up to one minute to retrieve and send the stored configuration after it receives the node's error.
This is the limit for a single attempt, not a service level agreement.

{{site.konnect_short_name}} doesn't send a rejected configuration to the same node again.
It also throttles repeated failures for the same node and the same rejected configuration.

### Check the configuration status of your nodes

To see the configuration status of your data plane nodes, call `GET /v2/control-planes/{controlPlaneId}/nodes`, or go to **API Gateway**, select a control plane, and click the **Data plane nodes** tab.
To see one node, call `GET /v2/control-planes/{controlPlaneId}/nodes/{nodeId}`, or select the node in the **Data plane nodes** tab.
Both endpoints return the node's `config_sync` state, the hash of the configuration it's running, and any errors it reported.
The `config_sync.state` field is one of `STATE_UNSPECIFIED`, `STATE_IN_SYNC`, `STATE_PENDING`, or `STATE_RESILIENCY`.
For a node on the last known good configuration, the `config_sync.resiliency` object includes the following fields:

* `fallback_hash`: The hash of the fallback configuration.
* `activated_at`: When the fallback was activated.
* `latest_config_errors`: The errors from the configuration that the node rejected.

For the full response, see the [Control Planes Config API](/api/konnect/control-planes-config/).

The **Configuration status** summary counts the nodes in each state, and lists the {{site.base_gateway}} versions that are running the last known good configuration.
The **Sync status** column shows one of the following statuses for each node:

{% table %}
columns:
  - title: Status
    key: status
  - title: Description
    key: description
rows:
  - status: In sync
    description: "The node is running the latest configuration."
  - status: Syncing
    description: "The node is receiving a configuration change."
  - status: Last known good config
    description: "The node is serving traffic, but not on the latest configuration. Select the node to see why."
  - status: No config
    description: "The node doesn't have a configuration applied and isn't serving traffic. Select the node to see why."
  - status: Unknown
    description: "Status can't be determined. Check the node connection and {{site.base_gateway}} version."
{% endtable %}

Select a node to open its details.
The **Current config** card explains why the node isn't running the latest configuration, and the error history shows which configurations the node rejected and why.
Hover over a **Sync status** badge to read the same explanation from the node list.

{:.info}
> The node list refreshes every 30 seconds while any node is **Syncing**, for up to five minutes.
> At other times, reload the page to see status changes.

A node can show **Last known good config** for three reasons:

{% table %}
columns:
  - title: Reason
    key: reason
  - title: What it means
    key: meaning
rows:
  - reason: "The node is running the last known good config because it rejected the latest config."
    meaning: "The node didn't have a configuration and rejected the latest one. {{site.konnect_short_name}} sent it the stored configuration for its {{site.base_gateway}} version."
  - reason: "The node is running its current config because it rejected the latest config."
    meaning: "The node was already running a configuration and kept it. {{site.konnect_short_name}} doesn't replace a configuration that a node is already running."
  - reason: "The node is running its current config because the control plane withheld the latest config."
    meaning: "{{site.konnect_short_name}} never sent the latest configuration, because the node's {{site.base_gateway}} version can't apply it. Check the **Compatibility** card and [version compatibility in control planes](/gateway/data-plane-version-compatibility/)."
{% endtable %}

### Last known good configuration and data plane resilience

{{site.konnect_short_name}} also supports [data plane resilience](/gateway/cp-outage/), which configures new nodes from a backup in object storage when the control plane is unreachable.
The two features cover different failures:

{% table %}
columns:
  - title: Feature
    key: feature
  - title: Failure it covers
    key: failure
  - title: Managed by
    key: owner
  - title: Setup
    key: setup
rows:
  - feature: Last known good configuration
    failure: "The control plane is running, but the node rejects the current configuration."
    owner: "{{site.konnect_short_name}}"
    setup: "None"
  - feature: "[Data plane resilience](/gateway/cp-outage/)"
    failure: "The control plane is unreachable."
    owner: "You"
    setup: "A backup node and S3-compatible or Google Cloud storage."
{% endtable %}

### Limitations

The last known good configuration is a recovery mechanism for nodes that can't apply the configuration they're sent, and it has the following limits:

* {{site.konnect_short_name}} never replaces a configuration that a node is already running. 
It also can't detect a configuration that's applied successfully but behaves incorrectly at runtime.

* {{site.konnect_short_name}} doesn't send a stored configuration to nodes using [incremental configuration sync](/gateway/incremental-config-sync/). 
A node that rejects its first configuration shows **No config**.

* A node must reach the control plane to receive a stored configuration. 
To configure nodes to load a configuration from object storage when the control plane is unreachable, see [Control Plane outage management](/gateway/cp-outage/).

* {{site.konnect_short_name}} stores configurations per {{site.base_gateway}} version, but whether a node can apply one also depends on its settings, such as its installed custom plugins, `KONG_PLUGINS`, and TLS verification. 
A node with more permissive settings can store a configuration that the rest of the fleet can't apply. 
Keep settings consistent across nodes running the same version.

* A node with stricter settings can reject both the latest and the stored configuration, and end up without a configuration. 
It shows **No config**.

* If no node on a {{site.base_gateway}} version has ever applied a configuration on this control plane, {{site.konnect_short_name}} doesn't have a stored configuration to send a node upgraded to that version. 
Bring nodes on the new version in sync before retiring the old ones.

* A node running the last known good configuration runs an older configuration than the one you last published. 
If the newer configuration addressed a vulnerability, that node doesn't have the fix.

* `/status/ready` returns `200` on a node that rejected the latest configuration, and `503` only on a node that doesn't have a configuration at all. 
A Kubernetes readiness probe keeps a node running the last known good configuration in rotation.

* {{site.konnect_short_name}} doesn't notify you when a node is sent the last known good configuration. 
Check the **Data plane nodes** tab or the API.

## Troubleshoot Data Plane nodes

Learn how to resolve some common issues with data plane nodes.

### Data plane node shows No config

**Problem:** A data plane node shows the **No config** sync status, which means it doesn't have a configuration applied and isn't serving traffic.

**Solution:** Select the node to read the explanation on the **Current config** card, then resolve the cause:

* **A last known good configuration isn't available for this {{site.base_gateway}} version.** 
No node running that version has applied a configuration on this control plane, so {{site.konnect_short_name}} doesn't have one to send. 
Fix the configuration the node rejected, or bring up a node on a version that can apply the current configuration.

* **The node rejected both the latest and the last known good configurations.** 
This usually means the node is missing a plugin that both configurations use. 
The error history lists each rejection separately. 
Install the missing plugins on the node, or publish a configuration the node can apply.

* **The node uses incremental configuration sync.** 
{{site.konnect_short_name}} doesn't send a last known good configuration to nodes using [incremental configuration sync](/gateway/incremental-config-sync/). 
Fix the configuration the node rejected.

### Data plane node shows Last known good config

**Problem:** A data plane node shows the **Last known good config** sync status. 
The node is serving traffic, but not on the configuration you last published.

**Solution:** Select the node and read the explanation on the **Current config** card:

* If the node rejected the latest configuration, the error history shows which configuration it rejected and why. 
Fix the configuration, or update the node so it can apply it. 

* If the control plane withheld the latest configuration, the node's {{site.base_gateway}} version can't apply it, and the node doesn't report an error of its own. 
Check the **Compatibility** card and [version compatibility in control planes](/gateway/data-plane-version-compatibility/).

### Data plane node isn't connecting

**Problem:** The {{site.konnect_short_name}} control plane can't communicate with a {{site.base_gateway}} data plane node.

**Solution:** Troubleshoot the issue using the following methods:

* Ensure the data plane node is running. If it's not running, start it; if it is running, restart it. 
After starting it, check the sync status in {{site.konnect_short_name}}.

* Check the logs of the data plane node. 
The default directory for {{site.base_gateway}} logs is [`/usr/local/kong/logs`](/gateway/configuration/#log-level).

    If you find any of the following errors:

    * Data Plane node failed to connect to the Control Plane.
    * Data Plane node failed to ping the Control Plane.
    * Data Plane node failed to receive a ping response from the Control Plane.
    * Invalid [configuration partials](/gateway/entities/partial/).

    You may have an issue on the host network where the node resides.
    Diagnose and resolve the issue, then restart the node and check the sync status in {{site.konnect_short_name}}.

If the logs show a license issue, or if you are unable to resolve sync issues using the above methods, contact Kong Support by navigating to the **?** icon on the top right menu and clicking **Create support case** or from the [Kong Support portal](https://support.konghq.com).

### Missing functionality

**Problem:** If a {{site.konnect_short_name}} feature isn’t working or isn't available on your Data Plane node, the version may be out of date.

**Solution:** Check that your Data Plane nodes are up to date, and update them if they are not. 
For Dedicated Cloud Gateways, see the [upgrade documentation](#upgrade-data-planes).

If you're running {{site.base_gateway}} in hybrid mode, check that the Data Plane node versions are up-to-date:

1. In {{site.konnect_short_name}}, navigate to [**API Gateway**](https://cloud.konghq.com/gateway-manager/) in the {{site.konnect_short_name}} sidebar.
1. Click your control plane.
1. Navigate to **Data Plane Nodes** in the sidebar.
1. Click **New Data Plane Node**.
1. Check the {{site.base_gateway}} version in the code block. 
This is the version that the {{site.konnect_short_name}} Control Plane is running.
1. Return to the Data Plane nodes page.
1. Check the Data Plane node versions in the table. 
If you see a node running an older version of {{site.base_gateway}}, your Data Plane node may need [upgrading](#upgrade-data-planes).

If your version is up-to-date but the feature still isn't working, contact Kong Support by navigating to the **?** icon on the top right menu and clicking **Create support case** or from the [Kong Support portal](https://support.konghq.com).

### Kubernetes Data Plane node installation doesn't work

**Problem:** You followed the Kubernetes installation instructions in the {{site.konnect_short_name}} UI but your Data Plane node isn't connecting.
 
**Solution:** Check your deployment logs for errors:

```bash
kubectl logs deployment/my-kong-kong -n kong
```

If you find any errors and need to update `values.yaml`, make your changes, save the file, then reapply the configuration by running the Helm `upgrade` command:

```bash
helm upgrade my-kong kong/kong -n kong \
  --values ./values.yaml
```
