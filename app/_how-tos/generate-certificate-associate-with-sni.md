---
title: Associate a Certificate with an SNI
content_type: how_to
related_resources:
  - text: Secure your API with TLS using SNIs
    url: /how-to/secure-api-with-tls/


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
    q: How do you associate a Certificate with an SNI and make sure it works?
    a: After creating a Certificate, you can associate it to a the desired SNI, and use `openssl` to verify that {{site.base_gateway}} is returning the expected certificate for the SNI. 
tools:
    - deck

prereqs:
  inline:
    - title: Certificate
      include_content: prereqs/certificate
      icon_url: /assets/icons/file.svg
    - title: Configure environment variables
      content: |
        Set the following variable: 
        * `SNI_NAME`: The name of the [SNI](/gateway/entities/sni/) that you intend to associate the Certificate to.
        For example: 
        ```sh
        export SNI_NAME=my.sni.example.com
        ```
    
cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
    

min_version:
    gateway: '3.4'
---


## 1. Associate your certificate with an SNI

Associate the Certificate created as a prerequisite with an SNI. If the SNI doesn't exist, this request will create a new one.

{% capture request %}
{% control_plane_request %}
  url: certificates/$CERT_ID/snis
  method: POST
  headers:
      - 'Accept: application/json'
      - 'Content-Type: application/json'
  body:
    name: $SNI_NAME
{% endcontrol_plane_request %}
{% endcapture %}

{{request | indent: 3}}

<!-- vale on -->

## 2. Validate 

Using `openssl`, open a connection with {{site.base_gateway}} and check that {{site.base_gateway}} returns the correct certificate for the SNI:

```
echo "" | openssl s_client -connect 127.0.0.1 -port 8443 -servername $SNI_NAME 2>/dev/null | openssl x509 -text -noout | head -10
```

The response will contain the certificate you created and attached to the SNI in the first step, along with the `CN` and any other information you used when creating the certificate. 
Because TLS passthrough is not enabled, {{site.base_gateway}} is returning its own Certificate. 
For instructions on configuring TLS passthrough, review our [Proxy TLS traffic](/how-to/proxy-tls-passthrough-traffic-using-sni/)
