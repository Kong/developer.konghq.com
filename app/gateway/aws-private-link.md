---
title: "AWS PrivateLink peering"
content_type: reference
layout: reference
description: |
  Create a private connection between your AWS environment and {{site.konnect_short_name}} using AWS PrivateLink.
products:
  - gateway
works_on:
  - konnect
api_specs:
  - konnect/control-planes-config

breadcrumbs:
  - /konnect/

related_resources:
  - text: AWS PrivateLink Interface Endpoints
    url: https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html
  - text: Amazon VPC Documentation
    url: https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html
  - text: AWS VPC peering
    url: /dedicated-cloud-gateways/aws-vpc-peering/

tags:
  - aws
  - security
---

You can establish a private connection between {{site.konnect_short_name}} and your AWS environment using AWS PrivateLink. This provides secure communication between your Data Plane and the Control Plane, reducing data transfer costs and ensuring compliance.

You can configure this instead of AWS Transit Gateways to secure your connection.

PrivateLink support is currently available in the following AWS regions:
* `us-east-1`
* `us-east-2`
* `us-west-2`
* `eu-central-1`
* `eu-west-1`
* `eu-west-2`
* `ap-east-1`
* `ap-southeast-1`
* `ap-southeast-2`
* `ap-northeast-1`
* `ap-northeast-3`

If your AWS region is not listed, contact Kong Support by navigating to the **?** icon on the top right menu and clicking **Create support case** or from the [Kong Support portal](https://support.konghq.com).

## AWS configuration for PrivateLink

Before creating a PrivateLink connection, ensure that you have a VPC, subnets, and a security group configured in your AWS account. For instructions, see the [Amazon VPC documentation](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html).


1. Navigate to **VPC > Endpoints** in the AWS Console.
1. Select **Create Endpoint**.
1. Choose the service category **Endpoint services that use Network Load Balancers and Gateway Load Balancers**.
1. Enter a name tag for the endpoint (for example, `konnect-us-geo`) indicating the {{site.konnect_short_name}} geo.
1. Locate the appropriate PrivateLink [service name from the tables](#regional-privatelink-service-names) in the following section based on your AWS region and {{site.konnect_short_name}} geo.
1. Select your VPC, subnets, and security group for the endpoint. Ensure the following settings are configured:
   * The security group allows inbound TCP traffic on port 443.
   * Private DNS is enabled in the additional settings.
1. Create the endpoint and wait until the status is available. We recommend waiting 10 minutes before using the endpoint.
1. After your PrivateLink endpoint is available, update your Data Plane configuration in the [`kong.conf` file](/gateway/manage-kong-conf/) to connect to the {{site.konnect_short_name}} Control Plane using the private DNS name for your region. 
   
   Locate your cluster prefix by making an API request to the Control Planes API:

{% capture prefix %}
<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes
status_code: 201
region: global
method: GET
headers:
  - 'Accept: application/json'
{% endkonnect_api_request %}
<!--vale on-->
{% endcapture %}

{{ prefix | indent }}

   In the response, look for `control_plane_endpoint`. Your cluster prefix is the first portion of the endpoint: `https://CLUSTER_PREFIX.cp.konghq.com`.

   Using the cluster prefix value from the response, put together a `kong.conf` configuration for the your region. For example, for the US region:
 
   ```sh
   cluster_control_plane = us.svc.konghq.com/cp/$CLUSTER_PREFIX
   cluster_server_name = us.svc.konghq.com
   cluster_telemetry_endpoint = us.svc.konghq.com:443/tp/$CLUSTER_PREFIX
   cluster_telemetry_server_name = us.svc.konghq.com
   ```

## Regional PrivateLink service names

The following tables show the PrivateLink service name and DNS name for each supported AWS region and {{site.konnect_short_name}} geo:
<!--vale off-->
{% navtabs "service names" %}

{% navtab "us-east-1" %}
{% table %}
columns:
  - title: {{site.konnect_short_name}} Geo
    key: geo
  - title: PrivateLink Service Name
    key: service
  - title: DNS Name
    key: dns
rows:
  - geo: AP
    service: com.amazonaws.vpce.us-east-1.vpce-svc-03eda50387fcc5e06
    dns: ap.svc.konghq.com/api
  - geo: EU
    service: com.amazonaws.vpce.us-east-1.vpce-svc-074b83bf704d87ba7
    dns: eu.svc.konghq.com/api
  - geo: GLOBAL
    service: com.amazonaws.vpce.us-east-1.vpce-svc-032c06bdabfc6005c
    dns: global.svc.konghq.com/api
  - geo: IN
    service: com.amazonaws.vpce.us-east-1.vpce-svc-0785a7867f5cbed8b
    dns: in.svc.konghq.com/api
  - geo: ME
    service: com.amazonaws.vpce.us-east-1.vpce-svc-09e6e8ec26383e748
    dns: me.svc.konghq.com/api
  - geo: SG
    service: com.amazonaws.vpce.us-east-1.vpce-svc-0925688dce5416901
    dns: sg.svc.konghq.com/api
  - geo: US
    service: com.amazonaws.vpce.us-east-1.vpce-svc-0a701662e3ebe10b8
    dns: us.svc.konghq.com/api
{% endtable %}
{% endnavtab %}

{% navtab "us-east-2" %}
{% table %}
columns:
  - title: {{site.konnect_short_name}} Geo
    key: geo
  - title: PrivateLink Service Name
    key: service
  - title: DNS Name
    key: dns
rows:
  - geo: AP
    service: com.amazonaws.vpce.us-east-2.vpce-svc-03da89378358921bc
    dns: ap.svc.konghq.com/api
  - geo: EU
    service: com.amazonaws.vpce.us-east-2.vpce-svc-0cb28c923823735ac
    dns: eu.svc.konghq.com/api
  - geo: GLOBAL
    service: com.amazonaws.vpce.us-east-2.vpce-svc-0b6f58f5e17620d89
    dns: global.svc.konghq.com/api
  - geo: IN
    service: com.amazonaws.vpce.us-east-2.vpce-svc-0b439785c0b06bb97
    dns: in.svc.konghq.com/api
  - geo: ME
    service: com.amazonaws.vpce.us-east-2.vpce-svc-0f1c86fb6399d4fe5
    dns: me.svc.konghq.com/api
  - geo: SG
    service: com.amazonaws.vpce.us-east-2.vpce-svc-05e1f7aec7fe36e70
    dns: sg.svc.konghq.com/api
  - geo: US
    service: com.amazonaws.vpce.us-east-2.vpce-svc-096fe7ba54ebc32db
    dns: us.svc.konghq.com/api
{% endtable %}
{% endnavtab %}

{% navtab "us-west-2" %}
{% table %}
columns:
  - title: {{site.konnect_short_name}} Geo
    key: geo
  - title: PrivateLink Service Name
    key: service
  - title: DNS Name
    key: dns
rows:
  - geo: AP
    service: com.amazonaws.vpce.us-west-2.vpce-svc-078156c9cc9048988
    dns: ap.svc.konghq.com/api
  - geo: EU
    service: com.amazonaws.vpce.us-west-2.vpce-svc-0e03b7c33104a4a4f
    dns: eu.svc.konghq.com/api
  - geo: GLOBAL
    service: com.amazonaws.vpce.us-west-2.vpce-svc-053325dfb74719cb9
    dns: global.svc.konghq.com/api
  - geo: IN
    service: com.amazonaws.vpce.us-west-2.vpce-svc-0865c535fc28a3060
    dns: in.svc.konghq.com/api
  - geo: ME
    service: com.amazonaws.vpce.us-west-2.vpce-svc-0fce4d5504650e9a3
    dns: me.svc.konghq.com/api
  - geo: SG
    service: com.amazonaws.vpce.us-west-2.vpce-svc-03d71f4a064877f2e
    dns: sg.svc.konghq.com/api
  - geo: US
    service: com.amazonaws.vpce.us-west-2.vpce-svc-0d2994122fea007ca
    dns: us.svc.konghq.com/api
{% endtable %}
{% endnavtab %}

{% navtab "eu-central-1" %}
{% table %}
columns:
  - title: {{site.konnect_short_name}} Geo
    key: geo
  - title: PrivateLink Service Name
    key: service
  - title: DNS Name
    key: dns
rows:
  - geo: AP
    service: com.amazonaws.vpce.eu-central-1.vpce-svc-0c3f0574080bdd859
    dns: ap.svc.konghq.com/api
  - geo: EU
    service: com.amazonaws.vpce.eu-central-1.vpce-svc-05e6822fbce58e1a0
    dns: eu.svc.konghq.com/api
  - geo: GLOBAL
    service: com.amazonaws.vpce.eu-central-1.vpce-svc-050c17c4f2970705f
    dns: global.svc.konghq.com/api
  - geo: IN
    service: com.amazonaws.vpce.eu-central-1.vpce-svc-0a5c165336502e526
    dns: in.svc.konghq.com/api
  - geo: ME
    service: com.amazonaws.vpce.eu-central-1.vpce-svc-0e6497e6df9928a80
    dns: me.svc.konghq.com/api
  - geo: SG
    service: com.amazonaws.vpce.eu-central-1.vpce-svc-0c43e67226a4aa910
    dns: sg.svc.konghq.com/api
  - geo: US
    service: com.amazonaws.vpce.eu-central-1.vpce-svc-01d3dd232e277feeb
    dns: us.svc.konghq.com/api
{% endtable %}
{% endnavtab %}

{% navtab "eu-west-1" %}
{% table %}
columns:
  - title: {{site.konnect_short_name}} Geo
    key: geo
  - title: PrivateLink Service Name
    key: service
  - title: DNS Name
    key: dns
rows:
  - geo: AP
    service: com.amazonaws.vpce.eu-west-1.vpce-svc-08edf59f8bc1d2262
    dns: ap.svc.konghq.com/api
  - geo: EU
    service: com.amazonaws.vpce.eu-west-1.vpce-svc-037bd988d9a9d4e3a
    dns: eu.svc.konghq.com/api
  - geo: GLOBAL
    service: com.amazonaws.vpce.eu-west-1.vpce-svc-0852df4643d76b28e
    dns: global.svc.konghq.com/api
  - geo: IN
    service: com.amazonaws.vpce.eu-west-1.vpce-svc-029c2f6bedf7c346f
    dns: in.svc.konghq.com/api
  - geo: ME
    service: com.amazonaws.vpce.eu-west-1.vpce-svc-0978fbaf50bfc67d9
    dns: me.svc.konghq.com/api
  - geo: SG
    service: com.amazonaws.vpce.eu-west-1.vpce-svc-02451d65748600af6
    dns: sg.svc.konghq.com/api
  - geo: US
    service: com.amazonaws.vpce.eu-west-1.vpce-svc-01070d7c2137e0ee1
    dns: us.svc.konghq.com/api
{% endtable %}
{% endnavtab %}

{% navtab "eu-west-2" %}
{% table %}
columns:
  - title: {{site.konnect_short_name}} Geo
    key: geo
  - title: PrivateLink Service Name
    key: service
  - title: DNS Name
    key: dns
rows:
  - geo: AP
    service: com.amazonaws.vpce.eu-west-2.vpce-svc-0500cb14757738225
    dns: ap.svc.konghq.com/api
  - geo: EU
    service: com.amazonaws.vpce.eu-west-2.vpce-svc-0b2d5879e15254e35
    dns: eu.svc.konghq.com/api
  - geo: GLOBAL
    service: com.amazonaws.vpce.eu-west-2.vpce-svc-06dfcb0204806e836
    dns: global.svc.konghq.com/api
  - geo: IN
    service: com.amazonaws.vpce.eu-west-2.vpce-svc-08e51a56a0ee549c6
    dns: in.svc.konghq.com/api
  - geo: ME
    service: com.amazonaws.vpce.eu-west-2.vpce-svc-0ab99eeae8121c7d8
    dns: me.svc.konghq.com/api
  - geo: SG
    service: com.amazonaws.vpce.eu-west-2.vpce-svc-0646cf4c72df9e4fc
    dns: sg.svc.konghq.com/api
  - geo: US
    service: com.amazonaws.vpce.eu-west-2.vpce-svc-0c23345bb2ef7b298
    dns: us.svc.konghq.com/api
{% endtable %}
{% endnavtab %}

{% navtab "ap-east-1" %}
{% table %}
columns:
  - title: {{site.konnect_short_name}} Geo
    key: geo
  - title: PrivateLink Service Name
    key: service
  - title: DNS Name
    key: dns
rows:
  - geo: AP
    service: com.amazonaws.vpce.ap-east-1.vpce-svc-0c7b67a477740b8cb
    dns: ap.svc.konghq.com/api
  - geo: EU
    service: com.amazonaws.vpce.ap-east-1.vpce-svc-0ca74e27b8d0a5c3c
    dns: eu.svc.konghq.com/api
  - geo: GLOBAL
    service: com.amazonaws.vpce.ap-east-1.vpce-svc-09dcb6580ddeff0ae
    dns: global.svc.konghq.com/api
  - geo: IN
    service: com.amazonaws.vpce.ap-east-1.vpce-svc-0731d524d482bfb04
    dns: in.svc.konghq.com/api
  - geo: ME
    service: com.amazonaws.vpce.ap-east-1.vpce-svc-09ca173aa8de2dd02
    dns: me.svc.konghq.com/api
  - geo: SG
    service: com.amazonaws.vpce.ap-east-1.vpce-svc-0b4d34906c77a8e29
    dns: sg.svc.konghq.com/api
  - geo: US
    service: com.amazonaws.vpce.ap-east-1.vpce-svc-02c00c62584350b46
    dns: us.svc.konghq.com/api
{% endtable %}
{% endnavtab %}

{% navtab "ap-southeast-1" %}
{% table %}
columns:
  - title: {{site.konnect_short_name}} Geo
    key: geo
  - title: PrivateLink Service Name
    key: service
  - title: DNS Name
    key: dns
rows:
  - geo: AP
    service: com.amazonaws.vpce.ap-southeast-1.vpce-svc-08f76d27d29b02a09
    dns: ap.svc.konghq.com/api
  - geo: EU
    service: com.amazonaws.vpce.ap-southeast-1.vpce-svc-0a04604ecaed18457
    dns: eu.svc.konghq.com/api
  - geo: GLOBAL
    service: com.amazonaws.vpce.ap-southeast-1.vpce-svc-0b1da0ec96942fdb0
    dns: global.svc.konghq.com/api
  - geo: IN
    service: com.amazonaws.vpce.ap-southeast-1.vpce-svc-0c6699c89ac27323c
    dns: in.svc.konghq.com/api
  - geo: ME
    service: com.amazonaws.vpce.ap-southeast-1.vpce-svc-00689717c9085d08a
    dns: me.svc.konghq.com/api
  - geo: SG
    service: com.amazonaws.vpce.ap-southeast-1.vpce-svc-06ec4681cc9fde9c9
    dns: sg.svc.konghq.com/api
  - geo: US
    service: com.amazonaws.vpce.ap-southeast-1.vpce-svc-0eeaa22ed2d6268eb
    dns: us.svc.konghq.com/api
{% endtable %}
{% endnavtab %}

{% navtab "ap-southeast-2" %}
{% table %}
columns:
  - title: {{site.konnect_short_name}} Geo
    key: geo
  - title: PrivateLink Service Name
    key: service
  - title: DNS Name
    key: dns
rows:
  - geo: AP
    service: com.amazonaws.vpce.ap-southeast-2.vpce-svc-055ba6ff5a3f551c9
    dns: ap.svc.konghq.com/api
  - geo: EU
    service: com.amazonaws.vpce.ap-southeast-2.vpce-svc-02a339e8dc8ec72c6
    dns: eu.svc.konghq.com/api
  - geo: GLOBAL
    service: com.amazonaws.vpce.ap-southeast-2.vpce-svc-0dddc28f5f8b68cbc
    dns: global.svc.konghq.com/api
  - geo: IN
    service: com.amazonaws.vpce.ap-southeast-2.vpce-svc-050ea149424be6d3c
    dns: in.svc.konghq.com/api
  - geo: ME
    service: com.amazonaws.vpce.ap-southeast-2.vpce-svc-008f231c7501e72c2
    dns: me.svc.konghq.com/api
  - geo: SG
    service: com.amazonaws.vpce.ap-southeast-2.vpce-svc-0619b7120e5eb737b
    dns: sg.svc.konghq.com/api
  - geo: US
    service: com.amazonaws.vpce.ap-southeast-2.vpce-svc-0600dd84f39e7b12a
    dns: us.svc.konghq.com/api
{% endtable %}
{% endnavtab %}

{% navtab "ap-northeast-1" %}
{% table %}
columns:
  - title: {{site.konnect_short_name}} Geo
    key: geo
  - title: PrivateLink Service Name
    key: service
  - title: DNS Name
    key: dns
rows:
  - geo: AP
    service: com.amazonaws.vpce.ap-northeast-1.vpce-svc-05a555912c88c3403
    dns: ap.svc.konghq.com/api
  - geo: EU
    service: com.amazonaws.vpce.ap-northeast-1.vpce-svc-01c086f3cb2a8e3b1
    dns: eu.svc.konghq.com/api
  - geo: GLOBAL
    service: com.amazonaws.vpce.ap-northeast-1.vpce-svc-0a5ef5e9cd65b180a
    dns: global.svc.konghq.com/api
  - geo: IN
    service: com.amazonaws.vpce.ap-northeast-1.vpce-svc-0f1fed745c08bb4c2
    dns: in.svc.konghq.com/api
  - geo: ME
    service: com.amazonaws.vpce.ap-northeast-1.vpce-svc-012f363a353acc0af
    dns: me.svc.konghq.com/api
  - geo: SG
    service: com.amazonaws.vpce.ap-northeast-1.vpce-svc-08b4f9a82fe4dd518
    dns: sg.svc.konghq.com/api
  - geo: US
    service: com.amazonaws.vpce.ap-northeast-1.vpce-svc-087f56ff74f855a49
    dns: us.svc.konghq.com/api
{% endtable %}
{% endnavtab %}

{% navtab "ap-northeast-3" %}
{% table %}
columns:
  - title: {{site.konnect_short_name}} Geo
    key: geo
  - title: PrivateLink Service Name
    key: service
  - title: DNS Name
    key: dns
rows:
  - geo: AP
    service: com.amazonaws.vpce.ap-northeast-3.vpce-svc-0774c82210d1e3a54
    dns: ap.svc.konghq.com/api
  - geo: EU
    service: com.amazonaws.vpce.ap-northeast-3.vpce-svc-016e2797bf4af4129
    dns: eu.svc.konghq.com/api
  - geo: GLOBAL
    service: com.amazonaws.vpce.ap-northeast-3.vpce-svc-07a3a4d6927b28ca8
    dns: global.svc.konghq.com/api
  - geo: IN
    service: com.amazonaws.vpce.ap-northeast-3.vpce-svc-0e7bbd9cd5c64cab4
    dns: in.svc.konghq.com/api
  - geo: ME
    service: com.amazonaws.vpce.ap-northeast-3.vpce-svc-0dea199a0496ca206
    dns: me.svc.konghq.com/api
  - geo: SG
    service: com.amazonaws.vpce.ap-northeast-3.vpce-svc-0c107ea8a747b0572
    dns: sg.svc.konghq.com/api
  - geo: US
    service: com.amazonaws.vpce.ap-northeast-3.vpce-svc-07eed5d5d58364be2
    dns: us.svc.konghq.com/api
{% endtable %}
{% endnavtab %}

{% endnavtabs %}
<!--vale on-->

