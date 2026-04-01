---
title: Test certificate generation locally with ngrok and the ACME plugin
permalink: /how-to/test-certificate-generation-locally-with-ngrok-and-acme/
description: Use ngrok and the ACME plugin to test certificate generation locally.
content_type: how_to
related_resources:
  - text: "{{site.base_gateway}} security"
    url: /gateway/security/

products:
    - gateway

works_on:
    - on-prem

entities: 
  - plugin
  - service
  - route

plugins:
  - acme

tags:
    - security
    - certificates

tldr:
    q: How do I test certificate generation locally with the ACME plugin?
    a: Use ngrok to create a domain, create a Service and Route that use your ngrok domain, and then enable the ACME plugin with `config.domains` set to your ngrok host. Generate a certificate with `curl https://$NGROK_HOST:8443 --resolve $NGROK_HOST:8443:127.0.0.1 -vk`. 

prereqs:
  inline:
    - title: ngrok
      content: |
        In this tutorial, we use [ngrok](https://ngrok.com/) to expose a local URL to the internet for local testing and development purposes. This isn't a requirement for the ACME plugin itself.

        1. [Install ngrok](https://ngrok.com/docs/getting-started/#step-1-install).
        1. [Sign up for an ngrok account](https://dashboard.ngrok.com/) and find your [ngrok authtoken](https://dashboard.ngrok.com/get-started/your-authtoken). 
        1. Install the authtoken and connect the ngrok agent to your account:
           ```sh
           ngrok config add-authtoken <TOKEN>
           ```
        1. Run ngrok:
           ```sh
           ngrok http localhost:8000
           ```
        1. Copy the Forwarding URL from the output and strip the `https://`.
        1. In a new terminal window, export it as a decK environment variable:
           ```sh
           export DECK_NGROK_HOST='YOUR FORWARDING URL'
           ```

tools:
  - deck

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'

automated_tests: false
---


## Configure a Service and Route

The [ACME](/plugins/acme/) plugin requires a Route to access the proxy to trigger certificate generation.

Create a [Gateway Service](/gateway/entities/service/) as well as a corresponding [Route](/gateway/entities/route/) that points to your ngrok host:

{% entity_examples %}
entities:
  services:
    - name: acme-test
      url: https://httpbin.konghq.com
  routes: 
    - name: acme-route
      service: 
        name: acme-test
      hosts: 
        - ${ngrok_host}

variables:
  ngrok_host:
    value: $NGROK_HOST
{% endentity_examples %}

## Enable the plugin

You can now enable the ACME plugin globally with ngrok as your domain:

{% entity_examples %}
entities:
  plugins:
    - name: acme
      config:
        account_email: test@test.com
        tos_accepted: true
        domains: 
          - ${ngrok_host}
        storage: kong

variables:
  ngrok_host:
    value: $NGROK_HOST
{% endentity_examples %}

## Create a certificate

Trigger certificate creation:

```sh
curl https://$DECK_NGROK_HOST:8443 --resolve $DECK_NGROK_HOST:8443:127.0.0.1 -vk
```

This might take a few seconds.

## Validate

Validate that the certificate was correctly created:

```sh
echo q |openssl s_client -connect localhost -port 8443 -servername $DECK_NGROK_HOST 2>/dev/null |openssl x509 -text -noout
```

You should see the certificate in the output.