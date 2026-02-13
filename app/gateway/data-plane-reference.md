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

## Troubleshoot Data Plane nodes

Learn how to resolve some common issues with Data Plane nodes.

### Out of sync Data Plane node

**Problem:** Occasionally, a {{site.base_gateway}} Data Plane node might get out of sync with the {{site.konnect_short_name}} Control Plane. 
If this happens, you will see the status `Out of sync` on the Data Plane Nodes page, meaning the Control Plane can't communicate with the node.

**Solution:** Troubleshoot the issue using the following methods:

* Ensure the Data Plane node is running. If it's not running, start it; if it is running, restart it. 
After starting it, check the sync status in {{site.konnect_short_name}}.

* Check the logs of the Data Plane node that's appearing as `Out of sync`. 
The default directory for {{site.base_gateway}} logs is [`/usr/local/kong/logs`](/gateway/configuration/#log-level).

    If you find any of the following errors:

    * Data Plane node failed to connect to the Control Plane.
    * Data Plane node failed to ping the Control Plane.
    * Data Plane node failed to receive a ping response from the Control Plane.
    * Invalid [configuration partials](https://developer.konghq.com/gateway/entities/partial/)

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
