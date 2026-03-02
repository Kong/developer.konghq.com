---
title: Set up Kong to serve an SSL certificate for API requests

content_type: support
description: Learn how to set up Kong to serve SSL certificates for API requests using self-signed certificates or certificates from a Certificate Authority.

products:
  - gateway

works_on:
  - on-prem
  - konnect

related_resources:
  - text: Certificate object reference
    url: /gateway/entities/certificate/
  - text: SNI object reference
    url: /gateway/entities/sni/

tldr: 
  q: How do I set up Kong to serve an SSL certificate for API requests?
  a: Create a certificate and key pair, then upload them to Kong by creating a Certificate entity and an SNI entity. The certificate will be served for requests matching the configured Server Name Indication (SNI).

---

The installation of Kong provides default SSL certificates for localhost. These are required to allow the HTTPS ports to start listening. Without these default certificates, it would not be possible to start any HTTPS listeners. It is recommended to change these certificates before moving to production.

In the example below, we will be creating our own CA and generating self-signed certificates from that CA. This means that clients will need to have access to the CA certificate to allow certificate verification. If you purchase a certificate from a well-known CA, then it is likely that the CA certificate will already be in the clients known CA list.

## Certificate creation 

1. Create a certificate/key pair for our own CA:

   ```bash
   openssl genrsa -out ca.key 4096
   openssl req -new -x509 -days 3650 -key ca.key -out ca.pem
   ```

2. Create a key for our desired host (`kong.lan`):

   ```bash
   openssl genrsa -out kong.lan.key 2048
   ```

3. Create a Certificate Signing Request (CSR) from our key. This will prompt you for details to include in the certificate. It is important to set the **Common Name** to match the hostname (for example, `kong.lan`):

   ```bash
   openssl req -new -key kong.lan.key -out kong.lan.csr
   ```

4. Sign the certificate with our CA. 

   {:.info}
   > **Note:** If you are using a well-known CA to generate the certificate, you will send them the CSR and they will provide the certificate. Your chosen CA will have details on the exact process they use for certificate generation.

   a. Create a file `kong.lan.ext` with the following contents:

      ```text
      authorityKeyIdentifier=keyid,issuer
      basicConstraints=CA:FALSE
      keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
      subjectAltName = @alt_names

      [alt_names]
      DNS.1 = kong.lan
      ```

   b. Create a certificate signed with our CA using the configuration file above:

      ```bash
      openssl x509 -req -in kong.lan.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out kong.lan.pem -days 1825 -sha256 -extfile kong.lan.ext
      ```

## Upload certificates to Kong

Now that we have a certificate (`kong.lan.pem`) and key (`kong.lan.key`) pair for the `kong.lan` domain, we need to upload these to Kong. This is done by creating a Certificate entity and an SNI entity that points to the Certificate entity.

1. Upload the certificate and key to Kong. We are creating the SNI entity with the same Admin API request:

   ```bash
   curl -X POST \
     https://localhost:8444/certificates \
     -H 'Content-Type: multipart/form-data' \
     -F cert=@./kong.lan.pem \
     -F key=@./kong.lan.key \
     -F snis[]=kong.lan
   ```

## Validate

Verify that Kong is serving the SSL certificate correctly:

```bash
curl --cacert ./ca.pem -v https://kong.lan:8443/
```

You should see output indicating a successful SSL connection:

```text
* SSL connection using TLSv1.2 / ECDHE-RSA-AES256-GCM-SHA384
* Server certificate:
*  subject: C=GB; ST=Hampshire; L=Aldershot; O=Kong; OU=Support; CN=kong.lan
*  subjectAltName: host "kong.lan" matched cert's "kong.lan"
*  SSL certificate verify ok.
```

The line `SSL certificate verify ok` confirms that the certificate was successfully verified and is being served by Kong for the `kong.lan` domain.