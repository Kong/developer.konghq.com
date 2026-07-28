---
title: How to set up Kong to serve a custom SSL certificate for API requests
content_type: support
description: Create a custom CA and certificate, then upload them to Kong to replace the default self-signed SSL certificate used for HTTPS API requests.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: curl SSL certificate problem docs
    url: https://curl.haxx.se/docs/sslcerts.html
tldr:
  q: How do I set up Kong to serve a custom SSL certificate for API requests?
  a: |
    Kong ships with a default self-signed certificate for `localhost`, which fails certificate validation for any other hostname. Create your own CA and a certificate/key pair for your hostname, sign the certificate with that CA, then upload the certificate and key to Kong as a Certificate entity with a matching SNI. Clients verifying the connection need the CA certificate (via `--cacert` for curl, or your OS/browser trust store).
---

## Overview

When accessing Kong APIs via HTTPS, the certificate is self-signed and for `localhost`. This causes the SSL connection to fail. For example, assuming the Kong server is available at the `kong.lan` domain name, the following request fails certificate validation:

```bash
curl -v https://kong.lan:8443/echo
*   Trying 10.0.10.1...
* TCP_NODELAY set
* Connected to kong.lan (10.0.10.1) port 8443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* Cipher selection: ALL:!EXPORT:!EXPORT40:!EXPORT56:!aNULL:!LOW:!RC4:@STRENGTH
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/cert.pem
  CApath: none
* TLSv1.2 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (OUT), TLS alert, Server hello (2):
* SSL certificate problem: self signed certificate
* stopped the pause stream!
* Closing connection 0
curl: (60) SSL certificate problem: self signed certificate
More details here: https://curl.haxx.se/docs/sslcerts.html
```

How can Kong be configured to use a different certificate for API requests?

## Steps

The installation of Kong provides default SSL certificates for `localhost`. These are required to allow the HTTPS ports to start listening. Without these default certificates, it would not be possible to start any HTTPS listeners. It is recommended to change these certificates before moving to production.

In the example below, we will be creating our own CA and generating self-signed certificates from that CA. This means that clients will need access to the CA certificate to allow certificate verification. If you purchase a certificate from a well known CA, then it is likely that the CA certificate will already be in the client's known CA list.

1) Create a certificate/key pair for our own CA

   ```bash
   openssl genrsa -out ca.key 4096
   openssl req -new -x509 -days 3650 -key ca.key -out ca.pem
   ```

2) Create a key for our desired host (`kong.lan`)

   ```bash
   openssl genrsa -out kong.lan.key 2048
   ```

3) Create a Certificate Signing Request (CSR) from our key. This will prompt you for details to include in the certificate. It is important to set the "Common Name" to match the hostname, i.e. `kong.lan`

   ```bash
   openssl req -new -key kong.lan.key -out kong.lan.csr
   ```

4) Sign the certificate with our CA. Note, if you are using a well known CA to generate the certificate then you will send them the CSR and they will provide the certificate. Your chosen CA will have details on the exact process they use for certificate generation.

   a) Create a file `kong.lan.ext` with the following contents:

      ```ini
      authorityKeyIdentifier=keyid,issuer
      basicConstraints=CA:FALSE
      keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
      subjectAltName = @alt_names

      [alt_names]
      DNS.1 = kong.lan
      ```

   b) Create a certificate signed with our CA using the configuration file above:

      ```bash
      openssl x509 -req -in kong.lan.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out kong.lan.pem -days 1825 -sha256 -extfile kong.lan.ext
      ```

Now that we have a certificate (`kong.lan.pem`) and key (`kong.lan.key`) pair for the `kong.lan` domain, we need to upload these to Kong. This is done by creating a Certificate entity and an SNI entity that points to the Certificate entity.

5) Upload the certificate and key to Kong. We are creating the SNI entity with the same Admin API request:

   ```bash
   curl -k -X POST \
     https://kong.lan:8444/certificates \
     -H 'Content-Type: multipart/form-data' \
     -F cert=@./kong.lan.pem \
     -F key=@./kong.lan.key \
     -F snis[]=kong.lan
   ```

6) It is now possible to call the API and use the certificates for the `kong.lan` domain. Remember to add the `--cacert` parameter when using curl, as we need to let curl use the CA certificate to verify the server certificate (you could also add the CA certificate to the default list of trusted CAs in `/etc/ssl/cert.pem`).

   ```bash
   curl --cacert ./ca.pem  -v https://kong.lan:8443/echo
   *   Trying 10.0.10.1...
   * TCP_NODELAY set
   * Connected to kong.lan (10.0.10.1) port 8443 (#0)
   * ALPN, offering h2
   * ALPN, offering http/1.1
   * Cipher selection: ALL:!EXPORT:!EXPORT40:!EXPORT56:!aNULL:!LOW:!RC4:@STRENGTH
   * successfully set certificate verify locations:
   *   CAfile: ./ca.pem
     CApath: none
   * TLSv1.2 (OUT), TLS handshake, Client hello (1):
   * TLSv1.2 (IN), TLS handshake, Server hello (2):
   * TLSv1.2 (IN), TLS handshake, Certificate (11):
   * TLSv1.2 (IN), TLS handshake, Server key exchange (12):
   * TLSv1.2 (IN), TLS handshake, Server finished (14):
   * TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
   * TLSv1.2 (OUT), TLS change cipher, Client hello (1):
   * TLSv1.2 (OUT), TLS handshake, Finished (20):
   * TLSv1.2 (IN), TLS change cipher, Client hello (1):
   * TLSv1.2 (IN), TLS handshake, Finished (20):
   * SSL connection using TLSv1.2 / ECDHE-RSA-AES256-GCM-SHA384
   * ALPN, server accepted to use http/1.1
   * Server certificate:
   *  subject: C=GB; ST=Hampshire; L=Aldershot; O=Kong; OU=Support; CN=kong.lan; emailAddress=support@konghq.com
   *  start date: Oct  9 10:22:26 2026 GMT
   *  expire date: Oct  7 10:22:26 2024 GMT
   *  subjectAltName: host "kong.lan" matched cert's "kong.lan"
   *  issuer: C=GB; ST=Hampshire; L=Aldershot; O=Kong Support; CN=Stuart's Own CA; emailAddress=stu@konghq.com
   *  SSL certificate verify ok.
   > GET /echo HTTP/1.1
   > Host: kong.lan:8443
   > User-Agent: curl/7.54.0
   > Accept: */*
   >
   < HTTP/1.1 200 OK
   < Content-Type: application/json
   < Content-Length: 337
   < Connection: keep-alive
   < Server: gunicorn/19.9.0
   < Date: Wed, 09 Oct 2026 11:00:38 GMT
   < Access-Control-Allow-Origin: *
   < Access-Control-Allow-Credentials: true
   < X-Kong-Upstream-Latency: 4
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
       "Connection": "keep-alive",
       "Host": "10.0.10.1",
       "User-Agent": "curl/7.54.0",
       "X-Forwarded-Host": "kong.lan"
     },
     "json": null,
     "method": "GET",
     "origin": "172.20.0.1",
     "url": "https://kong.lan/anything"
   }
   ```
