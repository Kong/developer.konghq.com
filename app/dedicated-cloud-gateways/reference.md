---
title: "Dedicated Cloud Gateways reference"
content_type: reference
layout: reference
description: "Dedicated Cloud Gateways are Data Plane nodes that are fully managed by Kong in {{site.konnect_short_name}}."

products:
    - gateway
breadcrumbs:
  - /dedicated-cloud-gateways/
works_on:
  - konnect

faqs:
  - q: Why is my custom domain attachment failing in {{site.konnect_short_name}}?
    a: |
      A common reason is a missing or misconfigured Certificate Authority Authorization (CAA) record. 
      {{site.konnect_short_name}} uses Google Cloud Public CA (`pki.goog`) to issue certificates. 
      If your domain's CAA record does not authorize this CA, attachment will fail.
  - q: What should I do if my custom domain fails to attach in {{site.konnect_short_name}}?
    a: |
      If your custom domain fails to attach, check whether your domain has a Certificate Authority Authorization (CAA) record that restricts certificate issuance. 
      {{site.konnect_short_name}} uses Google Cloud Public CA (`pki.goog`) to provision SSL/TLS certificates. If the CAA record doesn’t include `pki.goog`, certificate issuance will fail.

      To resolve the issue:
      1. Run `dig CAA yourdomain.com +short` to check for existing CAA records.
      2. If a record exists but doesn’t allow `pki.goog`, update it.
         ```
         yourdomain.com.    CAA    0 issue "pki.goog"
         ```
      3. Wait for DNS propagation and try attaching your domain again.

      If no CAA record exists, no changes are needed. For more details, see the [Let's Encrypt CAA Guide](https://letsencrypt.org/docs/caa/).
  - q: How often is DNS validation refreshed for Dedicated Cloud Gateways?
    a: |
      DNS validation statuses for Dedicated Cloud Gateways are refreshed every 5 minutes.
  - q: How do I delete a custom domain in {{site.konnect_short_name}}?
    a: |
      In {{site.konnect_short_name}}, go to [**API Gateway**](https://cloud.konghq.com/us/gateway-manager/), choose a Control Plane, click **Custom Domains**, and use the action menu to delete the domain.
  - q: How does network peering work with Dedicated Cloud Gateway nodes?
    a: |
      Each Cloud Gateway node is part of a dedicated network for its region (e.g., `us-east-1`). 
      You can securely peer this network with your AWS network using [AWS Transit Gateway](https://aws.amazon.com/transit-gateway/).
  - q: What happens if {{site.konnect_short_name}} goes down?
    a: |
      If the Kong-hosted Control Plane goes down, you won’t be able to access it or update configuration. 
      However, connected Data Plane nodes continue to route traffic normally using the last cached configuration.

  - q: Why isn’t AWS PrivateLink recommended for connecting Dedicated Cloud Gateway to my upstream services?
    a: |
      AWS PrivateLink offers secure and private connectivity by routing traffic through an endpoint, but it only supports unidirectional communication. 
      This means that Dedicated Cloud Gateway can send requests to your upstream services, but your upstream services cannot initiate communication back to the gateway. 
      For many use cases requiring bidirectional communication—such as callbacks or dynamic interactions between the gateway and your upstream services—this limitation is a blocker. 
      For this reason, PrivateLink is not generally recommended for secure connectivity to your upstream services.
  - q: How do I manage custom plugins after uploading them?
    a: |
      Once uploaded, you can manage custom plugins using any of the following methods:
      * [decK](/deck/)
      * [Control Plane Config API](/api/konnect/control-planes-config/v2/)
      * [{{site.konnect_short_name}} UI](https://cloud.konghq.com/)
  - q: How can I check if my Dedicated Cloud Gateway data plane is running?
    a: |
      You can use the `___konnect/healthz` endpoint to check if the data plane is up and ready. 
      For example: `https://dcgw-domain-here.aws-us-east-2.edge.gateways.konggateway.com/___konnect/healthz`

      This endpoint returns a `200 OK` response when the gateway is running. 
      
      {:.info}
      > **Note:** This is a basic health check and only confirms that the gateway process is up and running. 
      It doesn't verify routing, plugins, upstreams, or networking configurations.

related_resources:
  - text: Dedicated Cloud Gateways 
    url: /dedicated-cloud-gateways/
  - text: Serverless Gateways
    url: /serverless-gateways/
  - text: Private hosted zones
    url: /dedicated-cloud-gateways/private-hosted-zones/
  - text: Outbound DNS resolver
    url: /dedicated-cloud-gateways/outbound-dns-resolver/
next_steps:
  - text: Dedicated Cloud Gateways production readiness checklist
    url: /dedicated-cloud-gateways/production-readiness/
tags:
  - dedicated-cloud-gateways
---

## How do Dedicated Cloud Gateways work? 

When you create a Dedicated Cloud Gateway, {{site.konnect_short_name}} creates a **Control Plane**. 
This Control Plane, like other {{site.konnect_short_name}} Control Planes, is hosted by {{site.konnect_short_name}}. You can then deploy Data Planes in different [regions](/konnect-platform/geos/#dedicated-cloud-gateways).

Dedicated Cloud Gateways configures expected requests per second, and {{site.konnect_short_name}} pre-warms and autoscales the data plane nodes automatically.

<!-- vale off -->
{% mermaid %}
flowchart TD
A(Dedicated Cloud Gateway Control Plane)
B(Managed Data Plane Node <br> Region 1)
C(Managed Data Plane Node <br> Region 2)

subgraph id1 [Konnect]
A
end

A --auto-scale configuration---> B
A --auto-scale configuration---> C


{% endmermaid %}
<!--vale on -->
## How do I provision a Control Plane?

1. Create a Dedicated Cloud Gateway Control Plane using by issuing a `POST` request to the [Control Plane API](/api/konnect/control-planes/#/operations/create-control-plane):
<!-- vale off -->
{% capture request %}
{% control_plane_request %}
url: /v2/control-planes/
method: POST
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $KONNECT_TOKEN'
body:
  name: cloud-gateway-control-plane
  description: A test Control Plane for Dedicated Cloud Gateways.
  cluster_type: CLUSTER_TYPE_CONTROL_PLANE
  cloud_gateway: true
  proxy_urls:
    - host: example.com
    - port: 443
    - protocol: https
{% endcontrol_plane_request %}
{% endcapture %}
{{request | indent: 3}}
<!--vale on -->

2. Create a Dedicated Cloud Gateway Data Plane by issuing a `PUT` request to the [Cloud Gateways API](/api/konnect/cloud-gateways/#/operations/create-configuration):
<!--vale off -->
{% capture request %}
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
      version: 3.9
      control_plane_geo: ap-northeast-1
      dataplane_groups:
        - provider: aws 
        - region: na
        - cloud_gateway_network_id: $CLOUD_GATEWAY_NETWORK_ID
        - autoscale: 
          - kind: autopilot
          - base_rps: 100
  {% endcontrol_plane_request %}
{% endcapture %}
{{request | indent: 3}}
<!--vale on -->

## How do I segment the Dedicated Cloud Gateway by teams?

To isolate the Gateway configuration by team while still sharing a Dedicated Cloud Gateway cluster, you can use a Dedicated Cloud [control plane group](/gateway/control-plane-groups/). A Dedicated Cloud control plane group consists of hybrid control planes (typically segmented to teams) and Dedicated Cloud Gateway data plane nodes assigned to the control plane group. This allows you to segment your Dedicated Cloud Gateway like the following:

<!--vale off-->
{% mermaid %}
flowchart LR
 subgraph CPG["Dedicated Cloud CPG"]
        CP1("Control Plane:<br>Payments team config")
        CPP("Control Plane:<br>Platform Global<br>global config")
        CP2("Control Plane:<br>Orders team config")
  end
 subgraph ORG["**KONNECT ORG**"]
        CPG
  end

 subgraph RUNTIME["Dedicated Cloud runtime"]
    direction LR
        DPGA("DP: AWS us-east-1")
        DPGB("DP: AWS eu-west-1")
        DPGC("DP: Azure eastus2")
        DPGD("DP: Azure westeurope")
  end
    A("Team Payments") -- deck gateway sync --> CP1
    B("Team Orders") -- deck gateway sync --> CP2
    P("Platform Team") -- deck gateway sync --> CPP
    CPG -- Effective merged config --> RUNTIME
{% endmermaid %}
<!--vale on-->

In this example, the teams control the following:

**Team Payments control plane:**
* Payments Gateway Service
* Payments Routes
* Payments-specific rate limits

**Team Orders control plane:**
* Orders Gateway Service
* Orders Routes
* Orders-specific plugins

**Platform global control plane:**
* Global auth plugin
* Global logging plugin
* Managed cache config

The control plane group aggregates the hybrid control plane's configurations and passes them on to the Dedicated Cloud Gateway data plane nodes.

To configure a Dedicated Cloud control plane group, do the following:

1. In the {{site.konnect_short_name}} sidebar, click **API Gateway**.
1. Click **New**.
1. Select **New control plane group**.
1. In the **Name** field, enter `dcgw-control-plane-group`.
1. From the **Control Planes** dropdown menu, select your hybrid control plane that doesn't contain data plane nodes. 
1. For the Node Type, select **Dedicated Cloud**.
1. Click **Save**.
1. Click **Configure data plane**.
1. From the **Provider** dropdown menu, select the provider you want to configure.
1. From the **Region** dropdown menu, select the region you want to configure the cluster in. 
1. Edit the Network range as needed.
   
   {:.danger}
   > **Important:** Your provider network **must** use a different IP than your network in {{site.konnect_short_name}}, which is `10.0.0.0/16` by default but can be edited.
1. From the **Access** dropdown menu, select "Public" or "Private".
1. Click **Create data plane node**.
1. Click **Go to overview**.

## AWS workload identities

Dedicated Cloud Gateways support [AWS workload identities](https://docs.aws.amazon.com/rolesanywhere/latest/userguide/workload-identities.html) for data plane instances, enabling secure integration with your own AWS-managed services using IAM AssumeRole. This allows native and custom Kong plugins running in the data plane to access AWS services (like S3, Secrets Manager, Lambda, and DynamoDB) without static credentials, improving both security and operational simplicity.

Using AWS workload identities with Dedicated Cloud Gateways provides the following benefits:
* **Credential-less integration:** No need to manage or rotate static AWS credentials.
* **Security-first:** Workload identity is scoped to assume specific roles defined by you.
* **Compatibility:** Native and custom Kong plugins can seamlessly use AssumeRole credentials.

{:.info}
> This is currently only available for AWS. 

### How AWS workload identities works

1. When an AWS Dedicated Cloud Gateway is provisioned, {{site.konnect_short_name}} automatically creates the following:
   * An IAM Role in your dedicated tenant AWS account named after the network UUID. You can [derive this IAM Role ARN](#derive-the-konnect-iam-role-arn).
   * A trust policy that enables `AssumeRoleWithWebIdentity` for the EKS service account used by the {{site.base_gateway}} data planes. For example:
     ```json
     {
      "Version": "2012-10-17",
      "Statement": [{
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::*:root"
        },
        "Action": "sts:AssumeRole",
        "Condition": {
          "StringLike": {
            "aws:PrincipalArn": "arn:aws:iam::*:role/*"
          }
        }
      }]
    }
    ```
1. You define a trust relationship in your AWS account, allowing the Dedicated Cloud Gateway IAM role to assume a target role in your account.
1. The workload identity annotation on {{site.konnect_short_name}}'s service account is used to connect to this IAM role.

Keep the following security considerations in mind:
* The IAM role created by {{site.konnect_short_name}} is assume-only and has no permissions to manage infrastructure or cloud resources.
* You control which of your IAM roles {{site.konnect_short_name}} is allowed to assume by configuring trust relationships.

### Derive the {{site.konnect_short_name}} IAM Role ARN

You can compute the ARN for {{site.konnect_short_name}}'s IAM role using this pattern:

```
arn:aws:iam::$KONNECT_AWS_ACCOUNT_ID:role/$NETWORK_ID
```

1. To get the AWS account ID, do the following:
{% capture account_id %}
{% navtabs "aws-account-id" %}
{% navtab "UI" %}
1. In {{site.konnect_short_name}}, navigate to [**API Gateway**](https://cloud.konghq.com/gateway-manager/) in the sidebar.
1. Click your Dedicated Cloud Gateway.
1. Navigate to **Networks** in the sidebar.
1. Configure private networking and click **Transit Gateway**.
1. Copy the AWS account ID.
{% endnavtab %}
{% navtab "API" %}
Send a GET request to the [`/cloud-gateways/provider-accounts` endpoint](/api/konnect/cloud-gateways/v2/#/operations/list-provider-accounts):
<!--vale off-->
{% konnect_api_request %}
url: /v2/cloud-gateways/provider-accounts
method: GET
status_code: 200
region: global
{% endkonnect_api_request %}
<!--vale on-->
{% endnavtab %}
{% endnavtabs %}
{% endcapture %}

{{ account_id | indent: 3 }}

1. To fetch the UUID of the Network, do the following:
{% capture network_id %}
{% navtabs "network-uuid" %}
{% navtab "UI" %}
1. In {{site.konnect_short_name}}, navigate to [**API Gateway**](https://cloud.konghq.com/gateway-manager/) in the sidebar.
1. Click your Dedicated Cloud Gateway.
1. Navigate to **Data Plane Nodes** in the sidebar.
1. Copy the network ID from the data plane group table.
{% endnavtab %}
{% navtab "API" %}
Send a GET request to the [`/cloud-gateways/networks` endpoint](/api/konnect/cloud-gateways/v2/#/operations/list-networks):
<!--vale off-->
{% konnect_api_request %}
url: /v2/cloud-gateways/networks
method: GET
status_code: 200
region: global
{% endkonnect_api_request %}
<!--vale on-->
{% endnavtab %}
{% endnavtabs %}
{% endcapture %}

{{ network_id | indent: 3 }}


## Custom DNS
{{site.konnect_short_name}} integrates domain name management and configuration with [Dedicated Cloud Gateways](/dedicated-cloud-gateways/).

### {{site.konnect_short_name}} configuration

1. In {{site.konnect_short_name}}, navigate to [**API Gateway**](https://cloud.konghq.com/gateway-manager/) in the sidebar.
1. Click your control plane
1. Click **Connect**.
1. From the **Connect** menu, save the **Public Edge DNS** URL.
1. Navigate to **Custom Domains** in the sidebar.
1. Click **New Custom Domain**.
1. Enter your domain name.

    Save the value that appears under CNAME. 

### Dedicated Cloud Gateways domain registrar configuration

The following settings must be configured in your domain registrar using the values in {{site.konnect_short_name}}.
For example, in AWS Route 53, it would look like this:
<!--vale off -->
{% table %}
columns:
  - title: Host Name
    key: host
  - title: Record Type
    key: type
  - title: Routing Policy
    key: routing
  - title: Alias
    key: alias
  - title: Evaluate Target Health
    key: health
  - title: Value
    key: value
  - title: TTL
    key: ttl
rows:
  - host: "`_acme-challenge.example.com`"
    type: CNAME
    routing: Simple
    alias: No
    health: No
    value: "`_acme-challenge.9e454bcfec.acme.gateways.konggateway.com`"
    ttl: 300
  - host: "`example.com`"
    type: CNAME
    routing: Simple
    alias: No
    health: No
    value: "`9e454bcfec.gateways.konggateway.com`"
    ttl: 300
{% endtable %}
<!--vale on -->

## {{site.base_gateway}} configuration

The {{site.base_gateway}} configuration for your data plane nodes can be customized using environment variables.

The following table lists the environment variables that you can set while creating a Dedicated Cloud Gateway.

<!--vale off -->
{% kong_config_table env %}
config:
  - name: log_level
    description: |
      Log level of the data plane node.
      
      The logs are available in {{site.konnect_short_name}}, in the **Logs** tab of the data plane node.
  - name: request_debug_token
  - name: tracing_instrumentations
  - name: tracing_sampling_rate
  - name: untrusted_lua_sandbox_requires
  - name: allow_debug_header
  - name: header_upstream
    description: |
      Comma-separated list of headers Kong should inject in requests to upstream.

      At this time, the only accepted value is:

      * `X-Kong-Request-Id`: Unique identifier of the request.

      In addition, this value can be set to `off`, which prevents Kong from injecting the above header. Note that this does not prevent plugins from injecting headers of their own.
  - name: server_tokens
    description: Removes the Kong version information from the HTTP response headers.
  - name: latency_tokens
    description: Removes the latency information from the HTTP response headers.
  - name: real_ip_recursive
  - name: real_ip_header
  - name: headers
  - name: trusted_ips
{% endkong_config_table %}
<!--vale on -->

### How do I set environment variables?

In the {{site.konnect_short_name}} UI, you can add environment variables to a Dedicated Cloud Gateway when you create the data plane node. Navigate to your Dedicated Cloud Gateway control plane and from the **Actions** dropdown menu, select "Edit or Resize Cluster". Click **Advanced options** and enter the environment variable key and value pairs you want to use.

You can add environment variables using the Cloud Gateways API. When you [create a Dedicated Cloud Gateway Data Plane](#how-do-i-provision-a-control-plane) with a `PUT` request to the [`/cloud-gateways/configurations`](/api/konnect/cloud-gateways/#/operations/create-configuration) endpoint, add the `environment` array containing the `name` and `value` of each variable:
<!--vale off -->
{% konnect_api_request %}
url: /v2/cloud-gateways/configurations
region: global
status_code: 201
method: PUT
body:
  control_plane_id: $CONTROL_PLANE_ID
  version: "3.11"
  control_plane_geo: us
  dataplane_groups:
    - provider: aws
      region: us-east-2
      cloud_gateway_network_id: $CLOUD_GATEWAY_NETWORK_ID
      autoscale:
        kind: autopilot
        base_rps: 100
      environment:
        - name: KONG_TRACING_SAMPLING_RATE
          value: "0.01"
{% endkonnect_api_request %}
<!-- vale on -->

## CIDR size requirements

{% include /konnect/cidr-minimum-requirements.md %}

## Managed cache for Redis

{:.success}
> **Getting started with managed cache?**<br>
> For complete tutorials, see the following:
> * [Configure an AWS managed cache for a Dedicated Cloud Gateway control plane](/dedicated-cloud-gateways/aws-managed-cache-control-plane/)
> * [Configure an AWS managed cache for a Dedicated Cloud Gateway control plane group](/dedicated-cloud-gateways/aws-managed-cache-control-plane-group/)
> * [Configure an Azure managed cache for a Dedicated Cloud Gateway control plane](/dedicated-cloud-gateways/azure-managed-cache-control-plane/)
> * [Configure an Azure managed cache for a Dedicated Cloud Gateways control plane group](/dedicated-cloud-gateways/azure-managed-cache-control-plane-group/)

An managed cache for Dedicated Cloud Gateways is a Redis-compatible datastore that powers all Redis-enabled plugins. This is fully-managed by Kong in the provider and regions of your choice, so you don't have to host Redis infrastructure. Managed cache allows you get up and running faster with [Redis-backed plugins](/gateway/entities/partial/#use-partials), such as Proxy Caching, Rate Limiting, AI Rate Limiting, and ACME. 

Managed caches are either created at the control plane or control plane group-level. 

{% navtabs "managed-cache" %}
{% navtab "Control plane" %}
1. List your existing Dedicated Cloud Gateway control planes:
{% capture list_cp %}
<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes?filter%5Bcloud_gateway%5D=true
status_code: 201
method: GET
region: global
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ list_cp | indent: 3}}

1. Copy and export the control plane you want to configure the managed cache for:
   ```sh
   export CONTROL_PLANE_ID='YOUR CONTROL PLANE ID'
   ```

1. Create a managed cache using the Cloud Gateways add-ons API:

   {% capture create_addon %}
   <!--vale off-->
   {% konnect_api_request %}
   url: /v2/cloud-gateways/add-ons
   status_code: 201
   method: POST
   region: global
   body:
       name: managed-cache
       owner:
           kind: control-plane
           control_plane_id: $CONTROL_PLANE_ID
           control_plane_geo: us
       config:
           kind: managed-cache.v0
           capacity_config:
               kind: tiered
               tier: small
   {% endkonnect_api_request %}
   <!--vale on-->
   {% endcapture %}
   {{ create_addon | indent: 3}}

   When you configure a managed cache, you can select the small (~1 GiB capacity) cache size. Additional cache sizes will be supported in future updates. All regions are supported and you can configure the managed cache for multiple regions.

1. Export the ID of your managed cache in the response:
   ```sh
   export MANAGED_CACHE_ID='YOUR MANAGED CACHE ID'
   ```

1. Check the status of the managed cache. Once its marked as ready, it indicates the cache is ready to use:

   {% capture get_addon %}
   <!--vale off-->
   {% konnect_api_request %}
   url: /v2/cloud-gateways/add-ons/$MANAGED_CACHE_ID
   status_code: 200
   method: GET
   region: global
   {% endkonnect_api_request %}
   <!--vale on-->
   {% endcapture %}
   {{ get_addon | indent: 3}}

   This can take about 15 minutes. 

For control plane managed caches, you don't need to manually configure a Redis partial. After the managed cache is ready, {{site.konnect_short_name}} automatically creates a [Redis partial](/gateway/entities/partial/) configuration for you. [Use the redis configuration](/gateway/entities/partial/#add-a-partial-to-a-plugin) to setup Redis-supported plugins by selecting the automatically created {{site.konnect_short_name}}-managed Redis configuration. You can’t use the Redis partial configuration in custom plugins. Instead, use env referenceable fields directly.
{% endnavtab %}
{% navtab "Control plane group" %}
1. Create a managed cache using the Cloud Gateways add-ons API:

   {% capture create_addon %}
   <!--vale off-->
   {% konnect_api_request %}
   url: /v2/cloud-gateways/add-ons
   status_code: 201
   method: POST
   region: global
   body:
       name: managed-cache
       owner:
           kind: control-plane-group
           control_plane_group_id: $CONTROL_PLANE_GROUP_ID
           control_plane_group_geo: us
       config:
           kind: managed-cache.v0
           capacity_config:
               kind: tiered
               tier: small
   {% endkonnect_api_request %}
   <!--vale on-->
   {% endcapture %}
   {{ create_addon | indent: 3}}

   When you configure a managed cache, you can select the small (~1 GiB capacity) cache size. Additional cache sizes will be supported in future updates. All regions are supported and you can configure the managed cache for multiple regions.

1. Export the ID of your managed cache in the response:
   ```sh
   export MANAGED_CACHE_ID='YOUR MANAGED CACHE ID'
   ```

1. Check the status of the managed cache. Once its marked as ready, it indicates the cache is ready to use:

   {% capture get_addon %}
   <!--vale off-->
   {% konnect_api_request %}
   url: /v2/cloud-gateways/add-ons/$MANAGED_CACHE_ID
   status_code: 200
   method: GET
   region: global
   {% endkonnect_api_request %}
   <!--vale on-->
   {% endcapture %}
   {{ get_addon | indent: 3}}

   This can take about 15 minutes. 
1. Create a Redis partial configuration. The following example is for AWS:

{% capture create_redis_partial %}
<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/partials
status_code: 201
method: POST
region: us
body:
  name: konnect-managed
  type: redis-ee
  config:
    cloud_authentication:
      auth_provider: "{vault://env/ADDON_MANAGED_CACHE_AUTH_PROVIDER}"
      aws_cache_name: "{vault://env/ADDON_MANAGED_CACHE_AWS_CACHE_NAME}"
      aws_region: "{vault://env/ADDON_MANAGED_CACHE_AWS_REGION}"
      aws_is_serverless: false
      aws_assume_role_arn: "{vault://env/ADDON_MANAGED_CACHE_AWS_ASSUME_ROLE_ARN}"
    connect_timeout: 2000
    connection_is_proxied: false
    database: 0
    host: "{vault://env/ADDON_MANAGED_CACHE_HOST}"
    keepalive_backlog: 512
    keepalive_pool_size: 256
    port: "{vault://env/ADDON_MANAGED_CACHE_PORT}"
    read_timeout: 5000
    send_timeout: 2000
    server_name: "{vault://env/ADDON_MANAGED_CACHE_SERVER_NAME}"
    ssl_verify: true
    ssl: true
    username: "{vault://env/ADDON_MANAGED_CACHE_USERNAME}"
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}
{{ create_redis_partial | indent: 3 }}
1. Repeat the previous step for all the control planes in your control plane group.

You can apply the managed cache to any Redis-backed plugin by selecting the {{site.konnect_short_name}} partial for the shared Redis configuration.
{% endnavtab %}
{% endnavtabs %}

## Securing backend communication

Dedicated Cloud Gateways only support public networking. If your use case requires private connectivity, consider using [Dedicated Cloud Gateways](/dedicated-cloud-gateways/) with AWS Transit Gateways.

To securely connect a Dedicated Cloud Gateway to your backend, you can inject a shared secret into each request using the [Request Transformer plugin](/plugins/request-transformer).

1. Ensure the backend accepts a known token like an Authorization header.
1. Attach the Request Transformer plugin to the Control Plane and Gateway Service that you want to secure:
<!--vale off-->
{% capture request %}
{% control_plane_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/services/$SERVICE_ID/plugins
method: POST
status_code: 201
headers:
  - 'accept: application/json'
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $KONNECT_TOKEN'
body:
  name: request-transformer
  config:
    add:
      headers:
        - 'Authorization:Bearer $SECRET_TOKEN_VALUE'
{% endcontrol_plane_request %}
{% endcapture %}
{{ request | indent:3 }}
<!--vale on-->


### AWS Transit Gateway
If you are using Dedicated Cloud Gateways and your upstream services are hosted in AWS, AWS Transit Gateway is the preferred method for most users. For more information and a guide on how to attach your Dedicated Cloud Gateway, see the [Transit Gateways](/dedicated-cloud-gateways/transit-gateways/) documentation.

### Azure VNet Peering
If you are using Dedicated Cloud Gateways and your upstream services are hosted in Azure, VNet Peering is the preferred method for most users. For more information and a guide on how to attach your Dedicated Cloud Gateway, see the [Azure Peering](/dedicated-cloud-gateways/azure-peering/) documentation.

### GCP VPC Peering
If you are using Dedicated Cloud Gateways and your upstream services are hosted in GCP, VPC Network Peering is the preferred method for most users. For more information and a guide on how to attach your Dedicated Cloud Gateway, see the [GCP VPC Peering](/dedicated-cloud-gateways/gcp-vpc-peering/) documentation.

## Custom plugins

With Dedicated Cloud Gateways, {{site.konnect_short_name}} can stream [custom plugins](/custom-plugins/) from the Control Plane to the Data Plane. This means that the Control Plane becomes a single source of truth for plugin versions. You only need to upload a plugin once, to the Control Plane, and {{site.konnect_short_name}} handles distributing the plugin code to all Data Planes in that Control Plane. 

### How does custom plugin streaming work? 

With Dedicated Cloud Gateways, {{site.konnect_short_name}} can stream custom plugins from the Control Plane to the Data Plane. The Control Plane becomes the single source of truth for plugin versions. You only need to upload the plugin once, and {{site.konnect_short_name}} handles distribution to all Data Planes in the same Control Plane.

A custom plugin must meet the following requirements: 
* Unique name per plugin
* One `handler.lua` and one `schema.lua` file
* Cannot run in the `init_worker` phase or create timers
* Must be written in Lua
* A [personal or system access token](https://cloud.konghq.com/global/account/tokens) for the {{site.konnect_short_name}} API

### Custom plugin limitations

Keep the following custom plugin limitations in mind when adding them to Dedicated Cloud Gateways:

* Only `schema.lua` and `handler.lua` files are supported. Plugin logic must be self-contained in these two files. You can't use DAOs, custom APIs, migrations, or multiple Lua modules.
* Custom modules cannot be required when plugin sandboxing is enabled. Eternal Lua files or shared libraries can't be loaded.
* Custom validation must be implemented in `handler.lua`, not `schema.lua`. In `handler.lua`, it can be logged and handled as part of plugin business logic.
* Plugin files are limited to 100 KB per upload.
* Plugins cannot read/write to the {{site.base_gateway}} filesystem.
* The LuaJIT version is fixed per {{site.base_gateway}} version. Any future major Lua/LuaJIT upgrade will be communicated in advance due to potential breaking changes.

### How do I add a custom plugin?

Plugins can be uploaded to {{site.konnect_short_name}} using the [{{site.konnect_short_name}} UI](https://cloud.konghq.com/gateway-manager/).
You can also use [jq](https://jqlang.org/) with the following request template to add the plugin using the API:

```sh
curl -X POST $KONNECT_CONTROL_PLANE_URL/v2/control-planes/$CONTROL_PLANE_ID/core-entities/custom-plugins \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  -d "$(jq -n \
      --arg handler "$(cat handler.lua)" \
      --arg schema "$(cat schema.lua)" \
      '{"handler":$handler,"name":"streaming-headers","schema":$schema}')" \
    | jq
```
Once uploaded, you can manage custom plugins using any of the following methods:

* [decK](/deck/)
* [Control Plane Config API](/api/konnect/control-planes-config/v2/)
* [{{site.konnect_short_name}} UI](https://cloud.konghq.com/)
