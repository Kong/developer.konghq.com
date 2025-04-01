---
title: "AWS PrivateLink Peering"
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

related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: AWS PrivateLink Interface Endpoints
    url: https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html
  - text: Amazon VPC Documentation
    url: https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html
---

You can establish a private connection between {{site.konnect_short_name}} and your AWS environment using AWS PrivateLink. This provides secure communication between your Data Plane and the Control Plane, reducing data transfer costs and ensuring compliance.

PrivateLink support is currently available in the following AWS regions:

* `eu-central-1`
* `us-east-2`
* `eu-west-1`
* `eu-west-2`
* `ap-southeast-2`

If your desired AWS region is not listed, contact [Kong Support](https://support.konghq.com/support/s/).

## AWS configuration for PrivateLink

Before creating a PrivateLink connection, ensure that you have a VPC, subnets, and a security group configured in your AWS account. For guidance, refer to [Amazon VPC documentation](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html).

To configure PrivateLink:

1. Navigate to **VPC > Endpoints** in the AWS Console.
1. Select **Create Endpoint**.
1. Choose the service category **Endpoint services that use NLBs and GWLBs**.
1. Enter a name tag for the endpoint (e.g., `konnect-us-geo`) indicating the {{site.konnect_short_name}} geo.
1. Locate the appropriate PrivateLink service name from the tables below based on your AWS region and {{site.konnect_short_name}} geo.
1. Select your VPC, subnets, and security group for the endpoint. Ensure:
   * The security group allows inbound TCP traffic on port 443.
   * Private DNS is enabled in the additional settings.
1. Create the endpoint and wait until the status is **available**. We recommend waiting 10 minutes before using the endpoint.
1. After your PrivateLink endpoint is available, update your Data Plane configuration to connect to the {{site.konnect_short_name}} Control Plane using the private DNS name for your region.

Example `kong.conf` for the US region:

```sh
cluster_control_plane = us.svc.konghq.com/cp/{cluster_prefix}
cluster_server_name = us.svc.konghq.com
cluster_telemetry_endpoint = us.svc.konghq.com:443/tp/{cluster_prefix}
cluster_telemetry_server_name = us.svc.konghq.com
```


## Regional PrivateLink service names

The following tables show the PrivateLink service name and DNS name for each supported AWS region and {{site.konnect_short_name}} geo:

{% navtabs "service names" %}

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
    dns: ap.svc.konghq.com
  - geo: EU
    service: com.amazonaws.vpce.eu-central-1.vpce-svc-05e6822fbce58e1a0
    dns: eu.svc.konghq.com
  - geo: ME
    service: com.amazonaws.vpce.eu-central-1.vpce-svc-0e6497e6df9928a80
    dns: me.svc.konghq.com
  - geo: US
    service: com.amazonaws.vpce.eu-central-1.vpce-svc-01d3dd232e277feeb
    dns: us.svc.konghq.com
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
    dns: ap.svc.konghq.com
  - geo: EU
    service: com.amazonaws.vpce.us-east-2.vpce-svc-0cb28c923823735ac
    dns: eu.svc.konghq.com
  - geo: ME
    service: com.amazonaws.vpce.us-east-2.vpce-svc-0f1c86fb6399d4fe5
    dns: me.svc.konghq.com
  - geo: US
    service: com.amazonaws.vpce.us-east-2.vpce-svc-096fe7ba54ebc32db
    dns: us.svc.konghq.com
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
    dns: ap.svc.konghq.com
  - geo: EU
    service: com.amazonaws.vpce.eu-west-1.vpce-svc-037bd988d9a9d4e3a
    dns: eu.svc.konghq.com
  - geo: ME
    service: com.amazonaws.vpce.eu-west-1.vpce-svc-0978fbaf50bfc67d9
    dns: me.svc.konghq.com
  - geo: US
    service: com.amazonaws.vpce.eu-west-1.vpce-svc-01070d7c2137e0ee1
    dns: us.svc.konghq.com
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
    dns: ap.svc.konghq.com
  - geo: EU
    service: com.amazonaws.vpce.eu-west-2.vpce-svc-0b2d5879e15254e35
    dns: eu.svc.konghq.com
  - geo: ME
    service: com.amazonaws.vpce.eu-west-2.vpce-svc-0ab99eeae8121c7d8
    dns: me.svc.konghq.com
  - geo: US
    service: com.amazonaws.vpce.eu-west-2.vpce-svc-0c23345bb2ef7b298
    dns: us.svc.konghq.com
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
    dns: ap.svc.konghq.com
  - geo: EU
    service: com.amazonaws.vpce.ap-southeast-2.vpce-svc-02a339e8dc8ec72c6
    dns: eu.svc.konghq.com
  - geo: ME
    service: com.amazonaws.vpce.ap-southeast-2.vpce-svc-008f231c7501e72c2
    dns: me.svc.konghq.com
  - geo: US
    service: com.amazonaws.vpce.ap-southeast-2.vpce-svc-0600dd84f39e7b12a
    dns: us.svc.konghq.com
{% endtable %}

{% endnavtab %}

{% endnavtabs %}


