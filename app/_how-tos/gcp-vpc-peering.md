---
title: Set up a GCP VPC peering connection
description: 'Use the {{site.konnect_short_name}} Cloud Gateways API or the  {{site.konnect_short_name}} UI to create a VPC peering connection with your GCP VPC.'
content_type: how_to
permalink: /dedicated-cloud-gateways/gcp-vpc-peering/
breadcrumbs:
  - /dedicated-cloud-gateways/
products:
  - gateway
works_on:
  - konnect
automated_tests: false
tldr:
  q: How do I set up a Google Cloud VPC peering connection with my Dedicated Cloud Gateway?
  a: Use {{site.konnect_short_name}} to initiate peering, then create a GCP VPC peering resource to accept connections from {{site.konnect_short_name}}.
related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Google Cloud VPC Peering Documentation
    url: https://cloud.google.com/vpc/docs/vpc-peering
  - text: Private hosted zones
    url: /dedicated-cloud-gateways/private-hosted-zones/
  - text: Set up a GCP private DNS
    url: /dedicated-cloud-gateways/gcp-private-dns/
prereqs:
  skip_product: true
  inline:
    - title: "Dedicated Cloud Gateway"
      include_content: prereqs/dedicated-cloud-gateways

    - title: "GCP credentials and VPC"
      content: |
        Set up a GCP account with the [Compute Network Admin role](https://cloud.google.com/iam/docs/understanding-roles#compute.networkAdmin) (`roles/compute.networkAdmin`) or the following [custom permissions](https://cloud.google.com/iam/docs/custom-roles-permissions-support):
        * `compute.networks.addPeering`
        * `compute.networks.updatePeering`
        * `compute.networks.removePeering`
        * `compute.networks.listPeeringRoutes`
---

## Initiate the VPC peering connection

{% navtabs "configure-gcp-konnect" %}
{% navtab "Cloud Gateways API" %}

Export the following values as environment variables, setting your own custom values:
```sh
export GCP_VPC_PEERING_NAME='gcp vpc peering'
export GCP_PROJECT_ID='my-gcp-vpc-project'
export GCP_VPC_NAME='my-gcp-vpc-name'
```
Where:
* **VPC Peering Name**: A unique name to identify this VPC peering connection.
* **Project ID**: ID of your GCP project that contains the VPC you want to peer with Kong.
* **VPC Name**: Name of your VPC network in GCP for the peering connection.

Next, send the following request to the Cloud Gateways API:

<!--vale off-->
{% konnect_api_request %}
url: /v2/cloud-gateways/networks/$KONNECT_NETWORK_ID/transit-gateways
status_code: 201
region: global
method: POST
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
body:
  name: $GCP_VPC_PEERING_NAME
  transit_gateway_attachment_config:
    kind: gcp-vpc-peering-attachment
    peer_project_id: $GCP_PROJECT_ID
    peer_vpc_name: $GCP_VPC_NAME
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% navtab "Konnect UI" %}

1. From your Dedicated Cloud Gateway, open **Networks**.
1. Choose a network, open its action menu, and select **Configure Private Networking**.
1. Add a new VPC peering connection by filling out all of the required fields:
  * **VPC Peering Name**: A unique name to identify this VPC peering connection.
  * **Project ID**: ID of your GCP project that contains the VPC you want to peer with Kong.
  * **VPC Name**: Name of your VPC network in GCP for the peering connection.
1. Click **Next**.

{% endnavtab %}
{% endnavtabs %}

## Create a VPC peering resource in GCP

{% navtabs "configure-gcp-konnect" %}
{% navtab "Cloud Gateways API" %}

In {{site.konnect_short_name}}, you need to retrieve two pieces of data: the provider account ID and the VPC ID.

First, make a GET request to the {{site.konnect_short_name}} Cloud Gateways API using the `/provider-accounts` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/cloud-gateways/provider-accounts
status_code: 201
region: global
method: GET
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
{% endkonnect_api_request %}
<!--vale on-->

Save the `provider_account_id` from the output:

```
export PROVIDER_ACCOUNT_ID='your-provider-account-id'
```

Next, make a GET request to the `/networks` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/cloud-gateways/networks
status_code: 201
region: global
method: GET
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
{% endkonnect_api_request %}
<!--vale on-->

Save the `provider_metadata.vpc_id` from the output:

```
export PROVIDER_VPC_ID='your-provider-vpc-id'
```

In the GCP console, run the following command:

```sh
gcloud compute networks peerings create $GCP_VPC_PEERING_NAME \
  --network=$GCP_VPC_NAME \
  --peer-project=$PROVIDER_ACCOUNT_ID \
  --peer-network=$PROVIDER_VPC_ID \
  --stack-type=IPV4_ONLY \
  --import-custom-routes \
  --export-custom-routes \
  --import-subnet-routes-with-public-ip \
  --export-subnet-routes-with-public-ip \
  --project=$GCP_PROJECT_ID
```
{% endnavtab %}
{% navtab "Konnect UI" %}

{{site.konnect_short_name}} generates a command with all of the required values populated.
Copy the generated command and run it in the GCP console. 

The command will look something like this:

```sh
gcloud compute networks peerings create $GCP_VPC_PEERING_NAME \
  --network=$GCP_VPC_NAME \
  --peer-project=$PROVIDER_ACCOUNT_ID \
  --peer-network=$PROVIDER_VPC_ID \
  --stack-type=IPV4_ONLY \
  --import-custom-routes \
  --export-custom-routes \
  --import-subnet-routes-with-public-ip \
  --export-subnet-routes-with-public-ip \
  --project=$GCP_PROJECT_ID
```

{% endnavtab %}
{% endnavtabs %}

{:.info}
> Make sure that your VPC ranges don't conflict with the Cloud Gateway Network VPC range.

The peering connection status will initially show as `Initializing` and should change to `Ready` once peering is successfully established on both GCP and Kong. 

## Validation

To validate that everything was configured correctly, issue a `GET` request to the [`/transit-gateways`](/api/konnect/cloud-gateways/v2/#/operations/list-transit-gateways) endpoint to retrieve VPC peering information:

<!--vale off-->
{% konnect_api_request %}
url: /v2/cloud-gateways/networks/$KONNECT_NETWORK_ID/transit-gateways
status_code: 200
region: global
method: GET
{% endkonnect_api_request %}
<!--vale on-->
