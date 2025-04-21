---
title: "Data Plane Reference"
content_type: reference
layout: reference
description: | 
    Manage Data Plane nodes in {{site.konnect_short_name}}, including platform support, proxy access, version upgrades, certificate renewal, required parameters, and custom metadata labels.'

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
      By default, {{site.base_gateway}} listens on port `8000`, so a request to `http://localhost:8000/<your-route>` (or your custom hostname) 
      should return the expected response from your upstream service.

  - q: How do I access services through a Data Plane node running on Kubernetes?
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
  - q: Can I choose a specific {{site.base_gateway}} version when using Quickstart scripts in Gateway Manager?
    a: |
      Yes. Gateway Manager allows you to select the {{site.base_gateway}} version for your Quickstart scripts—except when using cloud provider scripts for AWS, Azure, and GCP. 
      This ensures compatibility and reduces errors caused by version mismatches.

  - q: Can I SSH directly into Konnect Data Plane nodes?
    a: |
      No. Direct SSH access is not possible because the SSH keys are randomly generated and not exposed. 
      To access nodes, use the cloud provider’s tools:
      * [AWS EC2 Instance Connect](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-connect-methods.html)
      * [Azure Cloud Shell](https://learn.microsoft.com/azure/cloud-shell/overview)
      * [Google Cloud SSH](https://cloud.google.com/compute/docs/instances/ssh)


related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Gateway Manager
    url: /gateway-manager/reference/
---


A Data Plane node is a single instance of {{site.base_gateway}} that acts as a proxy and serves traffic.
In {{site.konnect_short_name}}, Data Plane nodes are managed by [Control Planes](/gateway-manager/control-plane-groups/). Control planes manage and store configurations in {{site.konnect_short_name}}, and Data Plane nodes are configured according to the configuration distributed by the Control Plane.

{{site.konnect_short_name}} provides Data Plane node installation scripts for various platforms. 
These Data Plane nodes are configured to run in your {{site.konnect_short_name}} environment. Alternatively, {{site.konnect_short_name}} offers fully-managed Data Planes through [Dedicated Cloud Gateways](/dedicated-cloud-gateways).

## Supported installation options

{{site.konnect_short_name}} supports the following installation options:

{% table %}
columns:
  - title: Setup Type
    key: type
  - title: Platforms
    key: platforms
rows:
  - type: Standard setup
    platforms: macOS (ARM), macOS (Intel), Windows, Linux (Docker)
  - type: Advanced setup
    platforms: Linux, Kubernetes, AWS, Azure, Google Cloud
{% endtable %}


### Forward proxy support

{{site.konnect_product_name}} supports using non-transparent forward proxies to connect your {{site.base_gateway}} Data Plane with the {{site.konnect_short_name}} Control Plane. See the [Forward proxy connections](/gateway/cp-dp-communication/) {{site.base_gateway}} documentation for more information.



## Upgrade Data Planes

Self-managed Data Plane nodes can be upgraded to a new {{site.base_gateway}} by initializing new nodes before decommissioning old ones. This method ensures high availability, allowing the new node to commence data processing prior to the removal of the old node. Managed nodes are upgraded automatically after selecting the new version of {{site.base_gateway}}. We recommend running one major version (2.x or 3.x) of a Data Plane node per Control Plane, unless you are in the middle of version upgrades to the Data Plane. Mixing versions may cause [compatibility issues](/konnect-compatibility/).

To upgrade a Data Plane node to a new version, follow these steps:

{% navtabs "Upgrade" %}
{% navtab "Dedicated Cloud Gateways" %}

Using both the `control_plane_id`, `cloud_gateway_network_id`, and the desired [`version`](/konnect/compatibility/) you can use the API to upgrade a Data Plane node:
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


Kong performs a rolling upgrade of the fully-managed Data Plane nodes. This is a zero downtime upgrade because Kong synchronizes the Data Plane with load balancer registration and de-registration and gracefully terminates the old Data Plane nodes to reduce the impact on the ongoing traffic.

{% endnavtab %}


{% navtab "Hybrid-mode" %}


1. Open [**Gateway Manager**](https://cloud.konghq.com/us/gateway-manager/), choose a Control Plane,
and provision a new Data Plane node through the Gateway Manager.

    Make sure that your new Data Plane node appears in the list of nodes, 
    displays a _Connected_ status, and that it was last seen _Just Now_.

1. Once the new Data Plane node is connected and functioning, disconnect
and shut down the nodes you are replacing.

    {:.note}
    > You can't shut down Data Plane nodes from within Gateway Manager. Old
    nodes will also remain listed as `Connected` in Gateway Manager for a
    few hours after they have been removed or shut down.

1. Test passing data through your new Data Plane node by accessing your proxy
URL.

    For example, with the hostname `localhost` and the route path `/mock`:

    ```
    http://localhost:8000/mock
    ```
{% endnavtab %}
{% endnavtabs %}

## Data Plane Certificates

Data plane certificates generated by {{site.konnect_short_name}} expire every ten years. If you bring your own certificates, make sure to review the expiration date and associated metadata.

Renew your certificates to prevent any interruption in communication between
{{site.konnect_short_name}} and any configured Data Plane nodes. The following happens if a certificate expires and isn't replaced: 
* The Data Plane node stops receiving configuration updates from
the Control Plane.
* The Data Plane node stops sending [analytics](/advanced-analytics/) and usage data to the Control Plane.
* Each disconnected Data Plane node uses cached configuration to continue
proxying and routing traffic.

Depending on your setup, renewing certificates might mean bringing up a new data
plane, or generating new certificates and updating Data Plane nodes with the new
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
    description: "Sets the address of the {{site.konnect_short_name}} Control Plane. Must be in the format `host:port`, with port set to `443`.<br><br>**Example:**<br>Control plane endpoint in {{site.konnect_short_name}}:<br>`https://example.cp.khcp.konghq.com`<br>Configuration value:<br>`example.cp.khcp.konghq.com:443`"
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
    description: "Set to `off` to stop collecting Analytics data, or set to `on` to collect data and send it to the Control Plane for Analytics dashboards and metrics."
{% endtable %}


## Custom Data Plane labels

Labels are commonly used for metadata information. Set anything that you need to identify your Data Plane nodes -- deployment type, region, size, the team that the node belongs to, the purpose it serves, or any other identifiable information. For more information, review the [{{site.konnect_short_name}} labels](/gateway-manager/konnect-labels/) documentation.