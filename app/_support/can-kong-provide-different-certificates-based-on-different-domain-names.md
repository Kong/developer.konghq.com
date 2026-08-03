---
title: Serving different TLS certificates based on domain name using SNI
content_type: support
description: Kong can serve different TLS certificates per domain by matching the SNI field in the TLS handshake to a Certificate and SNI entity pair.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Can Kong provide different certificates based on different domain names?
  a: |
    Yes — Kong looks up the certificate to present based on the SNI field in the TLS Client Hello, so you can pair different `certificate` and `sni` entities with different domains, and even route to different services by SNI.
related_resources:
  - text: Certificate entity reference
    url: /gateway/entities/certificate/#schema
  - text: SNI entity reference
    url: /gateway/entities/sni/#schema
---

## Problem

Multiple domains proxied through Kong may each need their own TLS certificate, selected based on the domain name the client requests.

## Solution

Kong can present different certificates based on different domains by using SNIs.

When Kong receives an SSL request, it uses the SNI field in the Client Hello to look up the certificate object based on the SNI associated with the certificate.

With Kong Manager you can set up certificates in 2 steps, first adding the certificate and second linking the certificate to the SNI.

- Certificates > New Certificate

- SNI > New SNI

You can also set the certificate and set the SNI in a single Admin API call:

```bash
curl -H $KONG_ADMIN_TOKEN -X POST localhost:8001/certificates \
  -F cert=@./first-site.test-domain.com.crt \
  -F key=@./first-site.test-domain.com.key \
  -F snis[]=first-site.test-domain.com
```

We set the second certificate:

```bash
curl -H $KONG_ADMIN_TOKEN -X POST localhost:8001/certificates \
  -F cert=@./second-site.test-domain.com.crt \
  -F key=@./second-site.test-domain.com.key \
  -F snis[]=second-site.test-domain.com
```

To test if it works fine you can use this command with the different (`-servername`) and check that the certificates are different:

```bash
echo "" | openssl s_client -connect 127.0.0.1 -port 8443 -servername first-site.test-domain.com 2>/dev/null | openssl x509 -text -noout | head -10
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 4096 (0x1000)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = GB, ST = England, L = London, O = My Kong CA, OU = My Kong CA CX, CN = My Kong CA
        Validity
            Not Before: Apr 22 09:37:30 2024 GMT
            Not After : Apr 21 09:37:30 2026 GMT
        Subject: C = GB, ST = England, L = London, O = Kong, OU = Kong Servers, CN = first-site.test-domain.com
```

```bash
echo "" |openssl s_client -connect 127.0.0.1 -port 8443 -servername second-site.test-domain.com 2>/dev/null | openssl x509 -text -noout | head -10
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 4097 (0x1001)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = GB, ST = England, L = London, O = My Kong CA, OU = My Kong CA CX, CN = My Kong CA
        Validity
            Not Before: Apr 22 09:38:21 2024 GMT
            Not After : Apr 21 09:38:21 2026 GMT
        Subject: C = GB, ST = England, L = London, O = Kong, OU = Kong Servers, CN = second-site.test-domain.com
```

### Route based on SNI

You can also route based on SNIs, So you can create a route that routes to a service 1 based on SNI first-site.test-domain.com:

```bash
curl -H $KONG_ADMIN_TOKEN -X POST localhost:8001/services \
  -F name=service-1 \
  -F url=http://httpbin.org/anything

curl -H $KONG_ADMIN_TOKEN -X POST localhost:8001/services/service-1/routes \
  -F name=route-1-service-1 \
  -F paths[]=/ \
  -F snis[]=first-site.test-domain.com
```

And you can create a route that routes to a service 2 based on SNI second-site.test-domain.com:

```bash
curl -H $KONG_ADMIN_TOKEN -X POST localhost:8001/services \
  -F name=service-2 \
  -F url=http://mockbin.org/request

curl -H $KONG_ADMIN_TOKEN -X POST localhost:8001/services/service-2/routes \
  -F name=route-2-service-2 \
  -F paths[]=/ \
  -F snis[]=second-site.test-domain.com
```

You can also test using the curl command that everything works as expected:

```bash
curl -kv --resolve first-site.test-domain.com:8443:127.0.0.1 https://first-site.test-domain.com:8443
* Added first-site.test-domain.com:8443:127.0.0.1 to DNS cache
* Hostname first-site.test-domain.com was found in DNS cache
*   Trying 127.0.0.1:8443...
* TCP_NODELAY set
* Connected to first-site.test-domain.com (127.0.0.1) port 8443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/certs/ca-certificates.crt
  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN, server accepted to use http/1.1
* Server certificate:
*  subject: C=GB; ST=England; L=London; O=Kong; OU=Kong Servers; CN=first-site.test-domain.com
*  start date: Apr 22 09:37:30 2024 GMT
*  expire date: Apr 21 09:37:30 2026 GMT
*  issuer: C=GB; ST=England; L=London; O=My Kong CA; OU=My Kong CA CX; CN=My Kong CA
*  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
> GET / HTTP/1.1
> Host: first-site.test-domain.com:8443
> User-Agent: curl/7.68.0
> Accept: */*
> 
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Content-Type: application/json
< Content-Length: 457
< Connection: keep-alive
< Date: Fri, 22 Apr 2026 11:56:55 GMT
< Server: gunicorn/19.9.0
< Access-Control-Allow-Origin: *
< Access-Control-Allow-Credentials: true
< X-Kong-Upstream-Latency: 203
< X-Kong-Proxy-Latency: 1
< Via: kong/3.14.0.0-enterprise-edition
< 
{
  "args": {}, 
  "data": "", 
  "files": {}, 
  "form": {}, 
  "headers": {
    "Accept": "*/*", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.68.0", 
    "X-Amzn-Trace-Id": "Root=1-62629807-073a066d1b40861d31fa9812", 
    "X-Forwarded-Host": "first-site.test-domain.com", 
    "X-Forwarded-Path": "/"
  }, 
  "json": null, 
  "method": "GET", 
  "origin": "192.168.80.1, 139.47.115.181", 
  "url": "http://first-site.test-domain.com/anything"
}
* Connection #0 to host first-site.test-domain.com left intact
```

```bash
curl -kv --resolve second-site.test-domain.com:8443:127.0.0.1 https://second-site.test-domain.com:8443
* Added second-site.test-domain.com:8443:127.0.0.1 to DNS cache
* Hostname second-site.test-domain.com was found in DNS cache
*   Trying 127.0.0.1:8443...
* TCP_NODELAY set
* Connected to second-site.test-domain.com (127.0.0.1) port 8443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/certs/ca-certificates.crt
  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN, server accepted to use http/1.1
* Server certificate:
*  subject: C=GB; ST=England; L=London; O=Kong; OU=Kong Servers; CN=second-site.test-domain.com
*  start date: Apr 22 09:38:21 2024 GMT
*  expire date: Apr 21 09:38:21 2026 GMT
*  issuer: C=GB; ST=England; L=London; O=My Kong CA; OU=My Kong CA CX; CN=My Kong CA
*  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
> GET / HTTP/1.1
> Host: second-site.test-domain.com:8443
> User-Agent: curl/7.68.0
> Accept: */*
> 
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Content-Type: application/json; charset=utf-8
< Transfer-Encoding: chunked
< Connection: keep-alive
< Date: Fri, 22 Apr 2026 11:57:18 GMT
< Access-Control-Allow-Origin: *
< Access-Control-Allow-Methods: GET
< Access-Control-Allow-Headers: host,connection,accept-encoding,x-forwarded-for,cf-ray,x-forwarded-proto,cf-visitor,x-forwarded-host,x-forwarded-port,x-forwarded-path,user-agent,accept,cf-connecting-ip,cdn-loop,x-request-id,via,connect-time,x-request-start,total-route-time
< Access-Control-Allow-Credentials: true
< X-Powered-By: mockbin
< Vary: Accept, Accept-Encoding
< Etag: W/"430-U46ZZy6tOupAYL5lifAw0MNU+Ko"
< Via: kong/3.14.0.0-enterprise-edition
< CF-Cache-Status: DYNAMIC
< Report-To: {"endpoints":[{"url":"https:\/\/a.nel.cloudflare.com\/report\/v3?s=kzvRpvaEwlR6TVPP%2Fvua1G%2B3nODLHG1vAVOwRrLDE60zaEiEjziys%2BkFxKBAsSMJFaznNCkUUNndhgYk4aw14CKVkzAjIA5X8YZuq6WdnD7k9B1HcnAJvj9oInCKmQ%3D%3D"}],"group":"cf-nel","max_age":604800}
< NEL: {"success_fraction":0,"report_to":"cf-nel","max_age":604800}
< Server: cloudflare
< CF-RAY: 6ffe2e5addc673b7-MRS
< alt-svc: h3=":443"; ma=86400, h3-29=":443"; ma=86400
< X-Kong-Upstream-Latency: 234
< X-Kong-Proxy-Latency: 88
< 
{
  "startedDateTime": "2026-04-22T11:57:18.058Z",
  "clientIPAddress": "192.168.80.1",
  "method": "GET",
  "url": "http://second-site.test-domain.com/request",
  "httpVersion": "HTTP/1.1",
  "cookies": {},
  "headers": {
    "host": "mockbin.org",
    "connection": "close",
    "accept-encoding": "gzip",
    "x-forwarded-for": "192.168.80.1,139.47.115.181, 162.158.23.112",
    "cf-ray": "6ffe2e5addc673b7-MRS",
    "x-forwarded-proto": "http",
    "cf-visitor": "{\"scheme\":\"http\"}",
    "x-forwarded-host": "second-site.test-domain.com",
    "x-forwarded-port": "80",
    "x-forwarded-path": "/",
    "user-agent": "curl/7.68.0",
    "accept": "*/*",
    "cf-connecting-ip": "139.47.115.181",
    "cdn-loop": "cloudflare",
    "x-request-id": "ca1272a2-5897-4c0d-8d63-62f6148d4065",
    "via": "1.1 vegur",
    "connect-time": "0",
    "x-request-start": "1650628638058",
    "total-route-time": "0"
  },
  "queryString": {},
  "postData": {
    "mimeType": "application/octet-stream",
    "text": "",
    "params": []
  },
  "headersSize": 572,
  "bodySize": 0
* Connection #0 to host second-site.test-domain.com left intact
```
