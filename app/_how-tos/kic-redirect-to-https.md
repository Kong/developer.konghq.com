---
title: Redirect HTTP to HTTPS
description: "Redirect incoming HTTP requests to use HTTPS"
content_type: how_to
related_resources:
  - text: All KIC documentation
    url: /index/kubernetes-ingress-controller/

permalink: /kubernetes-ingress-controller/routing/http-to-https/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Routing

products:
  - kic

works_on:
  - on-prem
  - konnect

entities:
  - service
  - route

tags:
  - routing
  - redirect

tldr:
  q: How do I route traffic outside of my Kubernetes cluster?
  a: Configure an `ExternalName` service, then create an `HTTPRoute` to route traffic to the service.

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
      icon_url: /assets/icons/kubernetes.svg
---

{% assign demo_domain='example.com' %}

## Create an HTTPRoute

To route HTTP traffic, you need to create an `HTTPRoute` or an `Ingress` resource pointing at your Kubernetes `Service`.

<!--vale off-->
{% httproute %}
matches:
  - path: /echo
    service: echo
    port: 1027
skip_host: true
{% endhttproute %}
<!--vale on-->

## Add TLS configuration

{% include /k8s/add-tls.md namespace='kong' hostname=demo_domain cert_required=true %}

## Configure an HTTPS redirect

{{site.base_gateway}} handles HTTPS redirects by automatically issuing redirects to requests whose characteristics match an HTTPS-only route except for the protocol. For example, with a {{site.base_gateway}} Route like the following:

```json
{ "protocols": ["https"], "hosts": ["{{ demo_domain }}"],
  "https_redirect_status_code": 301, "paths": ["/echo/"], "name": "example" }
```
{:.no-copy-code}

A request for `http://{{ demo_domain }}/echo/green` receives a 301 response with a `Location: https://{{ demo_domain }}/echo/green` header. Kubernetes resource annotations instruct the controller to create a route with `protocols=[https]` and `https_redirect_status_code` set to the code of your choice (the default if unset is `426`).

1. Configure the protocols that are allowed in the `konghq.com/protocols` annotation:
{% capture the_code %}
{% navtabs codeblock %}
{% navtab "Gateway API" %}
```bash
kubectl annotate -n kong httproute echo konghq.com/protocols=https
```
{% endnavtab %}
{% navtab "Ingress" %}

```bash
kubectl annotate -n kong ingress echo konghq.com/protocols=https
```
{% endnavtab %}
{% endnavtabs %}
{% endcapture %}
{{ the_code | indent: 4 }}

1. Configure the status code used to redirect in the `konghq.com/https-redirect-status-code` annotation:
   {% capture the_code %}
{% navtabs codeblock %}
{% navtab "Gateway API" %}

```bash
kubectl annotate -n kong httproute echo konghq.com/https-redirect-status-code="301"
```
{% endnavtab %}
{% navtab "Ingress" %}

```bash
kubectl annotate -n kong ingress echo konghq.com/https-redirect-status-code="301"
```
{% endnavtab %}
{% endnavtabs %}
{% endcapture %}
{{ the_code | indent: 4 }}

{:.info}
> **Note**: {{ site.kic_product_name }} _does not_ use a [HTTPRequestRedirectFilter](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1.HTTPRequestRedirectFilter) to configure the redirect. Using the filter to redirect HTTP to HTTPS requires a separate `HTTPRoute` to handle redirected HTTPS traffic, which doesn't align well with {{site.base_gateway}}'s single Route redirect model.
> 
> Work to support the standard filter-based configuration is ongoing. Until then, the annotations allow you to configure HTTPS-only `HTTPRoutes`.

## Validate your configuration

With the redirect configuration in place, HTTP requests now receive a redirect rather than being proxied upstream:
1. Send an HTTP request:
    ```bash
    curl -ksvo /dev/null http://{{ demo_domain }}/echo --resolve {{ demo_domain }}:80:$PROXY_IP 2>&1 | grep -i http
    ```

    The results should look like this:

    ```text
    > GET /echo HTTP/1.1
    < HTTP/1.1 301 Moved Permanently
    < Location: https://{{ demo_domain }}/echo
    ```
    {:.no-copy-code}

1. Send a curl request to follow redirects using the `-L` flag. This navigates
to the HTTPS URL and receives a proxied response from the upstream.

    ```bash
    curl -Lksv http://{{ demo_domain }}/echo --resolve {{ demo_domain }}:80:$PROXY_IP --resolve {{ demo_domain }}:443:$PROXY_IP 2>&1
    ```

    The results should look like this (some output removed for brevity):

    ```text
    > GET /echo HTTP/1.1
    > Host: {{ demo_domain }}
    >
    < HTTP/1.1 301 Moved Permanently
    < Location: https://{{ demo_domain }}/echo
    < Server: kong/3.4.2
    
    * Issue another request to this URL: 'https://{{ demo_domain }}/echo'

    * Server certificate:
    *  subject: CN={{ demo_domain }}
     
    > GET /echo HTTP/2
    > Host: {{ demo_domain }}
    >
    < HTTP/2 200
    < via: kong/3.4.2
    <
    Welcome, you are connected to node kind-control-plane.
    Running on Pod echo-74d47cc5d9-pq2mw.
    In namespace default.
    With IP address 10.244.0.7.
    ```
    {:.no-copy-code}

{{site.base_gateway}} correctly serves the request only on the HTTPS protocol and redirects the user
if the HTTP protocol is used. The `-k` flag in cURL skips certificate
validation as the certificate is served by {{site.base_gateway}} is a self-signed one. If you are
serving this traffic through a domain that you control and have configured TLS
properties for it, then the flag won't be necessary.
