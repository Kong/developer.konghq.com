---
title: How to proxy SOAP requests in Kong
content_type: support
description: "Kong proxies SOAP requests like any other HTTP request, but proxying an HTTPS SOAP upstream requires uploading the full CA certificate chain to Kong's `ca_certificates` entity."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I proxy SOAP requests in Kong?
  a: |
    Kong proxies SOAP requests like any other HTTP request — no special configuration is needed to route them. If the SOAP upstream uses HTTPS, upload each certificate in the trust chain (including the root CA) as its own `ca_certificates` entity and list all the resulting IDs on the service, since Kong only accepts one certificate per `ca_certificates` entity.
---

## Overview

How to proxy SOAP requests in Kong

## Steps

Kong can proxy SOAP requests like any other HTTP request. The limitations come in when dealing with transforming and analyzing the data inside the request, however proxying is no problem.

Note: Kong verifies the upstream's TLS certificate by default. If the upstream is HTTPS, the service needs `ca_certificates` entries (and, depending on the certificate chain depth, `tls_verify_depth`) or the proxied request will fail with an upstream SSL verify error. Kong's `ca_certificates` entity only accepts one certificate per entity (`POST /ca_certificates` with more than one `-----BEGIN CERTIFICATE-----` block in `cert` fails schema validation with `"please submit only one certificate at a time"`), so each certificate in the trust chain must be uploaded as its own separate `ca_certificates` entity, with every resulting ID listed in the service's `ca_certificates` array. Also note the certificates the upstream sends during the handshake (visible via `openssl s_client -showcerts`) may not be the full trust path Kong needs — a cross-signed intermediate's own issuer (the actual self-signed root CA) can be missing from what the server presents, and that root must be uploaded too or verification still fails with `"unable to get issuer certificate"`.

See the below example:

Use decK to sync the following YAML and set up the route and service for the test:

```yaml

_format_version: "1.1"
services:
- connect_timeout: 60000
  enabled: true
  host: www.dataaccess.com
  name: soap-svc
  path: /webservicesserver/NumberConversion.wso
  port: 443
  protocol: https
  read_timeout: 60000
  retries: 5
  ca_certificates:
  - <ca-certificate-id-1>
  - <ca-certificate-id-2>
  - <ca-certificate-id-3>
  tls_verify_depth: 5
  routes:
  - https_redirect_status_code: 426
    name: soap-rt
    path_handling: v0
    paths:
    - /soap-test
    preserve_host: false
    protocols:
    - http
    - https
    regex_priority: 0
    request_buffering: true
    response_buffering: true
    strip_path: true
  write_timeout: 60000
```

`<ca-certificate-id-1>`, `<ca-certificate-id-2>`, `<ca-certificate-id-3>` refer to the target's CA certificate chain (intermediate(s) plus the ultimate root CA), each uploaded beforehand as its own separate `ca_certificates` entity in Kong (one certificate per entity) and referenced here by ID. Live-tested against `www.dataaccess.com` on {{site.base_gateway}} 3.14.0.0: uploading only the two non-leaf certificates the server itself presents during the TLS handshake produced a persistent `upstream SSL certificate verify error: (2: unable to get issuer certificate)`; the fix was uploading the actual trusted root CA (in this case Let's Encrypt's `ISRG Root X1`, obtainable from any standard CA bundle) as a third `ca_certificates` entity and adding its ID to the array above — after that, and after allowing a few seconds for the config to sync to the Data Plane, the request succeeded end-to-end.

This will setup an upstream SOAP service pointing to the upstream: https://www.dataaccess.com/webservicesserver/NumberConversion.wso

You should then be able to send the following SOAP payload to the upstream via this curl command:

```bash

curl --location --request POST 'http://kong-proxy:8000/soap-test' -k \
--header 'Content-Type: text/xml; charset=utf-8' \
--data-raw '<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
<soap:Body>
<NumberToWords xmlns="http://www.dataaccess.com/webservicesserver/">
<ubiNum>500</ubiNum>
</NumberToWords>
</soap:Body>
</soap:Envelope>'
```

Which should result in the following response:

```

<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <m:NumberToWordsResponse xmlns:m="http://www.dataaccess.com/webservicesserver/">
      <m:NumberToWordsResult>five hundred </m:NumberToWordsResult>
    </m:NumberToWordsResponse>
  </soap:Body>
</soap:Envelope>
```

You have successfully proxied SOAP traffic to a SOAP upstream.
