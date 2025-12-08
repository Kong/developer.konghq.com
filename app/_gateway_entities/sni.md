---
title: SNIs
content_type: reference
entities:
  - sni

description: An SNI object represents a many-to-one mapping of hostnames to a certificate.

related_resources:
  - text: Certificates
    url: /gateway/entities/certificate/
  - text: Reserved entity names
    url: /gateway/reserved-entity-names/
  - text: Using SSL certificates in {{site.base_gateway}}
    url: /gateway/ssl-certificates/
  - text: "{{site.konnect_short_name}} Control Plane resource limits"
    url: /gateway/control-plane-resource-limits/
      
tools:
    - admin-api
    - konnect-api
    - kic
    - deck
    - terraform
tags:
  - security
search_aliases:
  - hostname

api_specs:
    - gateway/admin-ee
    - konnect/control-planes-config

schema:
    api: gateway/admin-ee
    path: /schemas/SNI

works_on:
  - on-prem
  - konnect
---

## What is an SNI?

An SNI (Server Name Indication) is used to map multiple hostnames to a [Certificate](/gateway/entities/certificate/). It allows {{site.base_gateway}} to select which SSL/TLS Certificate to use based on the hostname in the client request. This feature ensures that multiple domains can be securely served through the same gateway.

## SNI routing

When configuring a Route with a secure protocol, like HTTPS, gRPC, or TLS, you can use an SNI for routing. The SNI is determined during the TLS handshake process and will remain unchanged for the duration of the connection, so all requests will contain the same SNI regardless of the defined `Header` in the Route configuration. For more information on how routing priorities are assigned read the [Expressions Router](/gateway/routing/expressions/#performance-considerations) documentation.

### Wildcards 

Valid wildcard positions for configuring SNIs are: 

* `mydomain.*`
* `*.mydomain.com`
* `*.www.mydomain.com`

This is especially useful when configuring [TLS Routes](/gateway/entities/#tls-route-configuration). 

### Prioritization matching

The prioritization for matching SNIs to Certificates follows this order:

 1. Exact SNI matching certificate
 2. Search for a certificate by an SNI prefix wildcard
 3. Search for a certificate by an SNI suffix wildcard
 4. Search for a certificate associated with the SNI `*`
 5. The default certificate on the file system

## Schema

{% entity_schema %}

## Set up an SNI

{% entity_example %}
type: sni
data:
  name: example-sni
  certificate:
    id: 2e013e8-7623-4494-a347-6d29108ff68b
{% endentity_example %}