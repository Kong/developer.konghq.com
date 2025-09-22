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

related_resources:
  - text: Dedicated Cloud Gateways 
    url: /dedicated-cloud-gateways/
  - text: Serverless Gateways
    url: /serverless-gateways/
  - text: Private hosted zones
    url: /dedicated-cloud-gateways/private-hosted-zones/
  - text: Outbound DNS resolver
    url: /dedicated-cloud-gateways/outbound-dns-resolver/
  - text: Dedicated Cloud Gateway domain breaking changes
    url: /dedicated-cloud-gateways/breaking-changes/

tags:
  - dedicated-cloud-gateways
---

{:.warning}
> **Dedicated Cloud Gateways domain breaking changes:** [Review domain breaking changes](/dedicated-cloud-gateways/breaking-changes/) for Dedicated Cloud Gateways and migrate to the new domain before September 30, 2025.

## How do Dedicated Cloud Gateways work? 

When you create a Dedicated Cloud Gateway, {{site.konnect_short_name}} creates a **Control Plane**. 
This Control Plane, like other {{site.konnect_short_name}} Control Planes, is hosted by {{site.konnect_short_name}}. You can then deploy Data Planes in different [regions](/konnect-platform/geos/#dedicated-cloud-gateways).

Dedicated Cloud Gateways support two different configuration modes:
* **Autopilot Mode:** Configure expected requests per second, and {{site.konnect_short_name}} pre-warms and autoscales the Data Plane nodes automatically.
* **Custom Mode:** Manually specify the instance size, type, and number of nodes per cluster.
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

The {{site.base_gateway}} configuration for your data plane nodes are customized using environment variables. Some variables are set by default, while others can be set when creating a data plane node.
{% comment %}
### Environment variables set by {{site.konnect_short_name}}

The following environment variables are set by default when creating a Dedicated Cloud Gateway data plane node:
<!--vale off -->
{% kong_config_table %}
config:
  - name: port_maps
    default_value: 80:443,443:8443,4200:4200
  - name: admin_listen
    default_value: 127.0.0.1:8444 http2 reuseport backlog=16384
  - name: status_listen
    default_value: 0.0.0.0:8100
  - name: admin_access_log
    default_value: /dev/stdout
  - name: admin_error_log
    default_value: /dev/stderr
  - name: proxy_error_log
    default_value: /dev/stderr
  - name: role
    default_value: data_plane
  - name: database
    default_value: off
  - name: cluster_mtls
    default_value: pki
  - name: lua_ssl_trusted_certificate
    default_value: system
  - name: konnect_mode
    default_value: one
  - name: vitals
    default_value: off
  - name: proxy_access_log
    default_value: off
  - name: request_debug
    default_value: on
  - name: "node_id"
  - name: "proxy_listen"
    default_value: 0.0.0.0:8000 reuseport proxy_protocol backlog=16384, 0.0.0.0:8443 http2 ssl reuseport proxy_protocol backlog=16384, 0.0.0.0:4200 reuseport proxy_protocol backlog=16384
  - name: "cluster_control_plane"
  - name: "cluster_server_name"
  - name: "cluster_telemetry_endpoint"
  - name: "cluster_telemetry_server_name"
directives:
  - name: nginx_proxy_proxy_socket_keepalive
    default_value: on
    description: ""
  - name: nginx_http_include
    default_value: /etc/nginx/nginx-directive.kong.conf
    description: ""
{% endkong_config_table %}
<!--vale on -->

### Customizable environment variables
{% endcomment %}
The following table lists the environment variables that you can set while creating a Dedicated Cloud Gateway.

{:.warning}
> These variables should be uppercase and prefixed with `KONG_`. For example, to add `log_level` use the `KONG_LOG_LEVEL` variable. 
<!--vale off -->
{% kong_config_table %}
config:
  - name: log_level
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

In the {{site.konnect_short_name}} UI, you can add environment variables at the **Create a Data Plane Node** step of the Dedicated Cloud Gateway creation. Click **Advanced options** to display the **Environment variables** form and enter the key/value pairs to use.

With the Cloud Gateways API, when you [create a Dedicated Cloud Gateway Data Plane](#how-do-i-provision-a-control-plane) with a `PUT` request to the [`/cloud-gateways/configurations`](/api/konnect/cloud-gateways/#/operations/create-configuration) endpoint, add the `environment` array containing the `name` and `value` of each variable:
<!--vale off -->
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
    environment:
      - name: KONG_LOG_LEVEL
        value: info
{% endcontrol_plane_request %}
<!-- vale on -->

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
