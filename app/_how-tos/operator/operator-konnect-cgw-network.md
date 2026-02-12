---
title: Create a Cloud Gateway Network
description: "Provision a Dedicated Cloud Gateway Network in {{site.konnect_short_name}} using the `KonnectCloudGatewayNetwork` CRD."
content_type: how_to


permalink: /operator/konnect/crd/cloud-gateways/network/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: "Konnect CRDs: Cloud Gateways"

products:
  - operator

works_on:
  - konnect

entities: []

tags:
  - konnect-crd
related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
tldr:
  q: How do I create a Dedicated Cloud Gateway Network using KGO?
  a: Use the `KonnectCloudGatewayNetwork` resource to provision a network and monitor provisioning status in {{site.konnect_short_name}}.


prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true
  inline: 
    - title: Provider Account ID
      include_content: /prereqs/provider-account-id

---

## Create a `KonnectCloudGatewayNetwork`

Use the `KonnectCloudGatewayNetwork` resource to provision a Dedicated Cloud Gateway Network in your selected region and availability zones.


<!-- vale off -->
{% konnect_crd %}
kind: KonnectCloudGatewayNetwork
apiVersion: konnect.konghq.com/v1alpha1
metadata:
  name: konnect-network-1
spec:
  name: network1
  cloud_gateway_provider_account_id: '$CLOUD_GATEWAY_PROVIDER_ID'
  availability_zones:
    - euw1-az1
    - euw1-az2
    - euw1-az3
  cidr_block: "192.168.0.0/16"
  region: eu-west-1
  konnect:
    authRef:
      name: konnect-api-auth
{% endkonnect_crd %}
<!-- vale on -->


## Validation
{% validation kubernetes-resource %}
kind: KonnectCloudGatewayNetwork
name: konnect-network-1
{% endvalidation %}