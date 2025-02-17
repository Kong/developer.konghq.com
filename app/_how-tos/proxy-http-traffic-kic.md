---
title: Proxy HTTP Traffic with KIC
content_type: how_to
related_resources: []

products:
  - kic

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: Question
  a: Answer

prereqs:
  kubernetes:
    gateway_api: true
  entities:
    services:
      - echo-service

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kic.svg
---

## Create a HTTPRoute

To route HTTP traffic, you need to create a `HTTPRoute` or an `Ingress` resource pointing at your Kubernetes `Service`.

{% include /k8s/httproute.md release=page.release path='/echo' name='echo' service='echo' port='1027' skip_host=true %}

## Validate your configuration

Once the resource has been reconciled, you'll be able to call the `/echo` endpoint and {{ site.base_gateway }} will route the request to the `echo` service.


{% validation request-check %}
url: /echo
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}
