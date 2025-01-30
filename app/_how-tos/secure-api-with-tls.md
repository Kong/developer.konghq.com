---
title: Secure your API with TLS using SNIs
content_type: how_to
related_resources:
  - text: SNI entity
    url: /gateway/entities/snis/
  - text: Certificates
    url: /gateway/entities/certificate/


products:
    - gateway

works_on:
    - on-prem
    - konnect

entities: 
  - certificate
  - sni
  - route
  - service

tldr:
    q: How do I set up {{site.base_gateway}} with TLS?
    a: By creating an SSL [Certificate](/gateway/entities/certificate), and associating it with an [SNI](/gateway/entities/sni), you can force {{site.base_gateway}} to handle encrypted traffic.
tools:
    - deck

prereqs:
  inline:
    - title: Certificate
      include_content: prereqs/certificate
    
cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'
---



{{site.base_gateway}} can proxy TLS requests using the client's TLS SNI extension as a forwarding mechanism. This allows a TLS request to be accepted without needing to decrypt it. 

## 1. Retrieve the ID of your certificate

{% capture request %}
{% control_plane_request %}
  url: certicates/
{% endcontrol_plane_request %}
{% endcapture %}

Copy the UUID in the response body to use in the next step. 

## 2. Associate your certificate with an SNI

{% capture request %}
{% control_plane_request %}
  url: certificates/{YOUR_CERT_ID}/snis
  method: POST
  body:
      name: "bob2.example.com"
{% endcontrol_plane_request %}
{% endcapture %}

{{request | indent: 3}}
<!-- vale on -->


## 3. Validate 

```
echo "" | openssl s_client -connect 127.0.0.1 -port 8443 -servername bob2.example.com 2>/dev/null | openssl x509 -text -noout | head -10
```