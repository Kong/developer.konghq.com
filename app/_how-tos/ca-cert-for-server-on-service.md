---
title: Define a CA certificate on a Service to verify server certificates
content_type: how_to

entities: 
  - ca-certificate
  - service

related_resources:
  - text: Define a client certificate on a Service
    url: /how-to/client-cert-for-service/
  - text: SSL certificates reference
    url: /gateway/ssl-certificates/

products:
    - gateway

works_on:
    - on-prem
    - konnect

tools:
    - deck
tldr:
  q: How do I define CA Certificates to verify upstream server certificates for a specific Gateway Service?
  a: Define a CA Certificate entity in {{site.base_gateway}}, and set the ID of that entity via the `ca_certificate` parameter of a Gateway Service.

prereqs:
  inline:
    - title: PEM-encoded CA certificate
      content: |
        {{site.base_gateway}} accepts PEM-encoded CA certificates signed by a central certificate authority (CA).
        Prepare your CA certificates on the host where {{site.base_gateway}} is running. 
      icon_url: /assets/icons/file.svg

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

Each Gateway Service has a `ca_certificates` property will hold an array of CA Certificate IDs.

## 1. Upload a CA Certificate

Replace the sample PEM-encoded certificate contents in the following example with your own:

{% entity_examples %}
entities:
  ca_certificates:
    - cert: |
        -----BEGIN CERTIFICATE-----
        MIIB4TCCAYugAwIBAgIUAenxUyPjkSLCe2BQXoBMBacqgLowDQYJKoZIhvcNAQEL
        BQAwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUxITAfBgNVBAoM
        GEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDAeFw0yNDEwMjgyMDA3NDlaFw0zNDEw
        MjYyMDA3NDlaMEUxCzAJBgNVBAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEw
        HwYDVQQKDBhJbnRlcm5ldCBXaWRnaXRzIFB0eSBMdGQwXDANBgkqhkiG9w0BAQEF
        AANLADBIAkEAyzipjrbAaLO/yPg7lL1dLWzhqNdc3S4YNR7f1RG9whWhbsPE2z42
        e6WGFf9hggP6xjG4qbU8jFVczpd1UPwGbQIDAQABo1MwUTAdBgNVHQ4EFgQUkPPB
        ghj+iHOHAKJlC1gLbKT/ZHQwHwYDVR0jBBgwFoAUkPPBghj+iHOHAKJlC1gLbKT/
        ZHQwDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAANBALfy49GvA2ld+u+G
        Koxa8kCt7uywoqu0hfbBfUT4HqmXPvsuhz8RinE5ltxId108vtDNlD/+bKl+N5Ub
        qKjBs0k=
        -----END CERTIFICATE-----
{% endentity_examples %}

## 2. Upload CA Certificate to {{site.base_gateway}}

Apply this configuration so that {{site.base_gateway}} generates a UUID for the CA Certificate.
You'll need to reference this UUID in your Gateway Service.

{% include how-tos/steps/apply_config.md %}

## 3. Retrieve CA Certificate ID

Run the following command:

```sh
curl -i -X GET http://localhost:8001/ca_certificates
```
{: data-deployment-topology="on-prem" }

```sh
curl -i -X GET https://$KONNECT_PROXY_URL.api.konghq.com/v2/control-planes/$KONNECT_CP_NAME/core-entities/ca_certificates/ \
    --header "Authorization: Bearer $KONNECT_TOKEN" \
```
{: data-deployment-topology="konnect" }

Copy the `id` of your CA Certificate from the output.

## 3. Create Gateway Service

Create a Gateway Service and reference the CA Certificate by its ID. 

Add the following to your `kong.yaml` file:

{% entity_examples %}
entities:
  services:
    - name: example_service
      host: httpbin.org
      protocol: https
      port: 443
      ca_certificates:
      - 4ae235fd-bcc0-4d08-9689-5ade8f143hjf7
      routes:
        - name: example_route
          paths:
            - /example
{% endentity_examples %}

## 4. Apply configuration

{% include how-tos/steps/apply_config.md %}

## 5. Validate 

Now, any time an upstream presents a server certificate, {{site.base_gateway}} will attempt to verify it using the CA root certificate linked to the Service.
<!-- 
Access the `example_route` Route: 

```sh
curl -v http://localhost:8443/example_route
```
 -->
