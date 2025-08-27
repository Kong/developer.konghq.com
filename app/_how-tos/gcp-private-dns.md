---
title: Set up a GCP private DNS for Dedicated Cloud Gateway
description: 'Use the {{site.konnect_short_name}} Cloud Gateways API or the {{site.konnect_short_name}} UI to create a private DNS with your GCP DNS zone.'
content_type: how_to
permalink: /dedicated-cloud-gateways/gcp-private-dns/
breadcrumbs:
  - /dedicated-cloud-gateways/
products:
  - gateway
works_on:
  - konnect
automated_tests: false
tldr:
  q: How do I set up a Google Cloud private DNS with my Dedicated Cloud Gateway?
  a: Create a private DNS in {{site.konnect_short_name}} using the [Create Private DNS endpoint](/api/konnect/cloud-gateways/v2/#/operations/create-private-dns), then create a [private DNS zone](https://cloud.google.com/dns/docs/zones) in GCP and give Kong access to it.
related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Set up a GCP VPC peering connection
    url: /dedicated-cloud-gateways/gcp-vpc-peering/
  - text: Google Cloud VPC peering documentation
    url: https://cloud.google.com/vpc/docs/vpc-peering
  - text: Google Cloud DNS zones documentation
    url: https://cloud.google.com/dns/docs/zones
  - text: Private hosted zones
    url: /dedicated-cloud-gateways/private-hosted-zones/
prereqs:
  skip_product: true
  inline:
    - title: "Dedicated Cloud Gateway"
      include_content: prereqs/dedicated-cloud-gateways

    - title: "GCP permissions"
      content: |
        This tutorial requires a GCP account with the [DNS Peer](https://cloud.google.com/iam/docs/roles-permissions/dns#dns.peer) (`roles/dns.peer`) and [DNS Administrator](https://cloud.google.com/iam/docs/roles-permissions/dns#dns.admin) (`roles/dns.admin`) roles, and the following [custom permissions](https://cloud.google.com/iam/docs/custom-roles-permissions-support):
        * `dns.managedZones.create`
        * `dns.managedZones.list`
        * `dns.networks.bindPrivateDNSZone`
        * `dns.networks.targetWithPeeringZone`
        * `dns.gkeClusters.bindPrivateDNSZone`
        * `dns.managedZones.update`
        * `dns.managedZones.list`
        * `dns.managedZones.patch`
        * `dns.activePeeringZones.getZoneInfo`
        * `dns.activePeeringZones.list`
        * `dns.activePeeringZones.deactivate`
    - title: "GCP project and VPC network"
      content: |
        This tutorial requires a GCP project and a [VPC network](https://cloud.google.com/vpc/docs/create-modify-vpc-networks).

        You will need the project ID and VPC name to configure the private DNS. Save these as environment variables to use them in {{site.konnect_short_name}} API requests:

        ```sh
        export GCP_PROJECT_ID='my-gcp-vpc-project'
        export GCP_VPC_NAME='my-gcp-vpc-name'
        ```

---

## Configure a private DNS in {{site.konnect_short_name}}

{% navtabs "configure-gcp-konnect" %}
{% navtab "Cloud Gateways API" %}

Export the private DNS name and domain to use as environment variables:

```sh
export DNS_NAME='my-gcp-private-dns'
export DOMAIN_NAME='example.com'
```

Next, send the following request to the Cloud Gateways API:

<!--vale off-->
{% konnect_api_request %}
url: /v2/cloud-gateways/networks/$KONNECT_NETWORK_ID/private-dns
status_code: 201
region: global
method: POST
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
body:
  name: $DNS_NAME
  private_dns_attachment_config:
    kind: gcp-private-hosted-zone-attachment
    domain_name: $DOMAIN_NAME
    peer_project_id: $GCP_PROJECT_ID
    peer_vpc_name: $GCP_VPC_NAME
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% navtab "Konnect UI" %}

1. From your Dedicated Cloud Gateway, open **Networks**.
1. Choose a network, open its action menu, and select **Configure private DNS**.
1. Fill out all of the required fields to configure the private DNS:
  * **Private hosted zone name**: A unique name to identify this private DNS.
  * **Domain name**: 
  * **Project ID**: ID of your GCP project.
  * **VPC network name**: Name of your VPC network in GCP for the peering connection.
1. Click **Next**.

{% endnavtab %}
{% endnavtabs %}

## Create a private DNS zone in GCP

{% navtabs "configure-gcp-konnect" %}
{% navtab "Cloud Gateways API" %}

1. Run this command on your project to create a private DNS zone:
```sh
   gcloud dns \
     --project=$GCP_PROJECT_ID \
     managed-zones create $DNS_NAME \
     --description="Konnect private DNS" \
     --dns-name=$DOMAIN_NAME \
     --visibility="private" \
     --networks=$GCP_VPC_NAME
   ```

1. Run this command to give permission to Kong’s service principal to access the project:
   ```sh
   gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
     --member="principal://iam.googleapis.com/projects/133260365532/locations/global/workloadIdentityPools/aws-hdp-prod/subject/system:serviceaccount:network-peering-controller:network-peering-controller" \
     --role="roles/dns.peer"
   ```

   If needed, you can also give Kong access to your whole GCP organization using your organization ID:
   ```sh
   gcloud organizations add-iam-policy-binding $GCP_ORGANIZATION_ID \
     --member="principal://iam.googleapis.com/projects/133260365532/locations/global/workloadIdentityPools/aws-hdp-prod/subject/system:serviceaccount:network-peering-controller:network-peering-controller" \
     --role="roles/dns.peer" 
   ```

{% endnavtab %}
{% navtab "Konnect UI" %}

1. Copy and run the commands provided. 
1. Click the **Please confirm if you have completed the above mentioned steps** checkbox and click **Connect**.

{% endnavtab %}
{% endnavtabs %}

## Validate

To validate that everything was configured correctly, issue a `GET` request to the [`/private-dns`](/api/konnect/cloud-gateways/v2/#/operations/list-private-dns) endpoint to retrieve private DNS information:

<!--vale off-->
{% konnect_api_request %}
url: /v2/cloud-gateways/networks/$KONNECT_NETWORK_ID/private-dns
status_code: 200
region: global
method: GET
{% endkonnect_api_request %}
<!--vale on-->