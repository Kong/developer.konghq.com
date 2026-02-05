---
title: "OIDC with {{ site.kic_product_name }}"
short_title: OIDC
description: "Authenticate requests using the OpenID Connect protocol and {{ site.base_gateway }}"
content_type: how_to

permalink: /kubernetes-ingress-controller/oidc/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: How To

plugins:
  - oidc
  
search_aliases:
  - oidc
  - openid-connect

tags:
  - openid-connect
  - authentication

products:
  - kic

tools:
  - kic

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: How do I configure the OpenID Connect (OIDC) plugin with {{ site.kic_product_name }}?
  a: Create a `KongPlugin` instance containing your `client_id`, `client_secret`, and `grant_type`, then annotate a Service or Route with `konghq.com/plugins=my-oidc-plugin`.

prereqs:
  enterprise: true
  kubernetes:
    gateway_api: true
  entities:
    services:
      - echo-service
    routes:
      - echo
cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg
---

## About OpenID Connect

{{site.ee_product_name}}'s OIDC plugin can authenticate requests using the OpenID Connect protocol. Learn how to set up the OIDC plugin using the {{ site.kic_product_name }}.

{% include prereqs/kubernetes/keycloak.md render_inline=true %}

## Configure the OpenID Connect plugin

This example uses `keycloak.$PROXY_IP.nip.io` as the host, but you can use any domain name of your choice. For demo purposes, you can use the nip.io service to avoid setting up a DNS record.

{% entity_example %}
type: plugin
data:
  name: openid-connect
  config:
    issuer: https://keycloak.$PROXY_IP.nip.io/realms/master
    client_id:
    - $CLIENT_ID
    client_secret:
    - $CLIENT_SECRET
    redirect_uri:
    - http://$PROXY_IP/echo

  service: echo
{% endentity_example %}

## Validate your configuration

Once the resource has been reconciled, you'll be able to call the `/echo` endpoint and {{ site.base_gateway }} will route the request to the `echo` Service.

If you make a request without any authentication credentials, the request will fail with an `HTTP 302` and a redirect to the Keycloak login page:

{% validation request-check %}
url: /echo
status_code: 302
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
display_headers: true
{% endvalidation %}

If you provide a password the request will be proxied successfully:

{% validation request-check %}
url: /echo
user: "alex:password"
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}
