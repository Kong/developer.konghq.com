---
title: "Custom Domains"
content_type: reference
layout: reference
description: "{{site.konnect_short_name}} integrates domain name management and configuration with [Dedicated Cloud Gateways](/dedicated-cloud-gateways/)."

products:
    - gateway
faqs:
  - q: What should I do if my custom domain fails to attach in {{site.konnect_short_name}}?
    a: |
      If your custom domain fails to attach, check whether your domain has a Certificate Authority Authorization (CAA) record that restricts certificate issuance. 
      {{site.konnect_short_name}} uses Google Cloud Public CA (`pki.goog`) to provision SSL/TLS certificates. If the CAA record doesn’t include `pki.goog`, certificate issuance will fail.

      To resolve the issue:
      1. Run `dig CAA yourdomain.com +short` to check for existing CAA records.
      2. If a record exists but doesn’t allow `pki.goog`, update it.
         `yourdomain.com.    CAA    0 issue "pki.goog"`
      3. Wait for DNS propagation and try attaching your domain again.

      If no CAA record exists, no changes are needed. For more details, see the [Let's Encrypt CAA Guide](https://letsencrypt.org/docs/caa/).

  - q: How do I configure a custom domain in {{site.konnect_short_name}}?
    a: |
      In {{site.konnect_short_name}}, go to [**Gateway Manager**](https://cloud.konghq.com/us/gateway-manager/), select a Control Plane, open the **Overview** dashboard, click **Connect**, and save the **Public Edge DNS** URL. 
      Then, navigate to **Custom Domains**, click **New Custom Domain**, enter your domain name, and save the CNAME and Content values.

  - q: What DNS records do I need to add at my domain registrar for a custom domain?
    a: |
      You need to create CNAME records using the values provided in {{site.konnect_short_name}}.
      * `_acme-challenge.example.com` → `_acme-challenge.9e454bcfec.acme.gateways.konghq.com`
      * `example.com` → `9e454bcfec.gateways.konghq.com`

  - q: How often is DNS validation refreshed for Dedicated Cloud Gateways?
    a: |
      DNS validation statuses for Dedicated Cloud Gateways are refreshed every 5 minutes.
  
  - q: How do I delete a custom domain in {{site.konnect_short_name}}?
    a: |
      In {{site.konnect_short_name}}, go to [**Gateway Manager**](https://cloud.konghq.com/us/gateway-manager/), choose a Control Plane, click **Custom Domains**, and use the action menu to delete the domain.

  - q: Why is my custom domain attachment failing in {{site.konnect_short_name}}?
    a: |
      A common reason is a missing or misconfigured Certificate Authority Authorization (CAA) record. 
      {{site.konnect_short_name}} uses Google Cloud Public CA (`pki.goog`) to issue certificates. 
      If your domain's CAA record does not authorize this CA, attachment will fail.

  - q: How can I fix CAA record issues for a custom domain?
    a: |
      Use `dig CAA yourdomain.com +short` to check for existing CAA records. 
      If needed, update the record to allow `pki.goog`, like this,
      `yourdomain.com.    CAA    0 issue "pki.goog"`  
      Then, wait for DNS propagation and retry the domain attachment.

related_resources:
  - text: Konnect Advanced Analytics
    url: /advanced-analytics/
---


{{site.konnect_short_name}} integrates domain name management and configuration with [Dedicated Cloud Gateways](/dedicated-cloud-gateways/).

## {{site.konnect_short_name}} configuration

1. Open **Gateway Manager**, choose a control plane to open the **Overview** dashboard, then click **Connect**.
    
    The **Connect** menu will open and display the URL for the **Public Edge DNS**. Save this URL.

1. Select **Custom Domains** from the side navigation, then **New Custom Domain**, and enter your domain name.

    Save the value that appears under **CNAME**. 

## Dedicated Cloud Gateways domain registrar configuration

To configure 
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
    value: "`_acme-challenge.9e454bcfec.acme.gateways.konghq.com`"
    ttl: 300
  - host: "`example.com`"
    type: CNAME
    routing: Simple
    alias: No
    health: No
    value: "`9e454bcfec.gateways.konghq.com`"
    ttl: 300
{% endtable %}
