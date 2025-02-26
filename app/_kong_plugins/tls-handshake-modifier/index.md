---
title: 'TLS Handshake Modifier'
name: 'TLS Handshake Modifier'

content_type: plugin

publisher: kong-inc
description: 'Requests a client to present its client certificate'
tier: enterprise


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.1'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways

icon: tls-handshake-modifier.png

categories:
  - security

search_aliases:
  - tls-handshake-modifier
  - certificates
---

## Overview

The TLS Handshake Modifier plugin allows you to request a client certificate and make it available to other plugins acting on a request. it must be used in conjunction with the [TLS Metadata Headers](/plugins/tls-metadata-headers/) plugins, which is used to detect client certificates in requests.

This plugin requests a client certificate, but does not require it. It doesn’t perform any validation of the client certificate.

## Client certificate request

{{site.base_gateway}} asks for the client certificate on every handshake if the TLS Handshake Modifier plugin is configured on any Route or Service.

In most cases, the failure of the client to present a client certificate doesn’t affect subsequent proxying if that Route or Service doesn't have the TLS Handshake Modifier plugin applied. However, when the client is a desktop browser, it prompts the end user to choose the client certificate to send. This can lead to user experience issues rather than proxy behavior problems.

To improve this situation, Kong builds an in-memory map of SNIs from the configured {{site.base_gateway}} Routes that should present a client certificate. To limit client certificate requests during a handshake while ensuring the client certificate is requested when needed, the in-memory map is dependent on all the Routes in {{site.base_gateway}} having the SNIs attribute set. 

{{site.base_gateway}} must request the client certificate:
* On every request when the plugin is enabled globally.
* On every request when the plugin is applied at the Service or Route level and one or more Routes don't have SNIs set.
* On specific requests only when the plugin is applied at the Route level and all Routes have SNIs set.

If you want to restrict the handshake request for client certificates to specific requests, all Routes must have SNIs.