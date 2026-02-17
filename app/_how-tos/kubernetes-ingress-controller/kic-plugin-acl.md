---
title: ACL
description: "Apply the ACL plugin to provide access control for specific routes"
content_type: how_to

permalink: /kubernetes-ingress-controller/acl/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: How To
plugins:
  - acl
  - key-auth
search_aliases:
  - kic acl
products:
  - kic

tools:
  - kic

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: How do I apply the ACL plugin using {{ site.kic_product_name }}?
  a: |
    Create a `Secret` with a `konghq.com/credential: acl` label and apply it to the Consumer that you want to access the Service.

    {% details %}
    summary: |
      View details
    content: |
      ```bash
      echo '
      apiVersion: v1
      kind: Secret
      metadata:
        name: admin-acl
        labels:
          konghq.com/credential: acl
      stringData:
        group: admin
      ' | kubectl apply -f -
      ```

      Update an existing consumer to uses these credentials:

      ```bash
      kubectl patch --type json kongconsumer my-admin \
      -p='[{
        "op":"add",
        "path":"/credentials/-",
        "value":"admin-acl"
      }]'
      ```

      Then apply the ACL plugin to the service you want to protect

      {% capture example %}
      {% entity_example %}
      type: plugin
      data:
        name: admin-acl
        plugin: acl
        config:
          allow:
            - admin

        service: my-service
      {% endentity_example %}
      {% endcapture %}
      {{example | indent: 2}}
    {% enddetails %}

prereqs:
  kubernetes:
    gateway_api: true
    gateway_api_optional: true
  entities:
    services:
      - echo-service
    routes:
      - secured-endpoint
      - sensitive-endpoint

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg
---

## How the ACL plugin works

The ACL plugin compares a list of required `groups` on a [Gateway Service](/gateway/entities/service/) or [Route](/gateway/entities/route/) entity with the list of groups listed in an ACL credential that is attached to a [Consumer](/gateway/entities/consumer/). If the Consumer doesn't have the required `group`, the request is denied.

There are two distinct concepts with the ACL name:

1. The ACL **plugin**, which contains a list of groups a Service or Route requires
1. The ACL **credential**, which contains a list of groups a Consumer is in

Both of these entities must be configured for the ACL plugin to work.

## Provision consumers

Because the ACL plugin is attached to a Consumer, we need two Consumers added to {{ site.base_gateway }} to demonstrate how the ACL plugin works. These Consumers will use the [Key Authentication](/plugins/key-auth/) plugin to identify the Consumer from the incoming request.

1. Create secrets to add `key-auth` credentials for `my-admin` and `my-user`:

   ```bash
   echo '
   apiVersion: v1
   kind: Secret
   metadata:
     name: my-admin-key-auth
     namespace: kong
     labels:
       konghq.com/credential: key-auth
   stringData:
     key: my-admin-password
   ---
   apiVersion: v1
   kind: Secret
   metadata:
     name: my-user-key-auth
     namespace: kong
     labels:
       konghq.com/credential: key-auth
   stringData:
     key: my-user-password
   ' | kubectl apply -f -
   ```

1. Create two Consumers that are identified by these secrets:

{% entity_example %}
type: consumer
data:
  username: my-admin
  credentials:
    - my-admin-key-auth
  
indent: 4
{% endentity_example %}

{% entity_example %}
type: consumer
data:
  username: my-user
  credentials:
    - my-user-key-auth
  
indent: 4
{% endentity_example %}

## Secure the service

The Key Auth plugin must be added to a Service or Route to identify the Consumer from the incoming request. Add the `key-auth` plugin to the `echo` Service:

{% entity_example %}
type: plugin
data:
  name: key-auth
  
  service: echo
{% endentity_example %}

## Create ACL credentials

The Key Auth plugin and other {{site.base_gateway}} authentication plugins only provide authentication, not authorization. They can identify a Consumer, and reject any unidentified requests, but not restrict which Consumers can access which protected URLs. Any Consumer with a key auth credential can access any protected URL, even when the plugins for those URLs are configured separately.

To provide authorization, or restrictions on which Consumers can access which URLs, you need to also add the [ACL](/plugins/acl/) plugin, which can assign groups to Consumers and restrict access to URLs by group. 

Create two plugins, one which allows only an admin group, and one which allows both admin and user.

1. Generate ACL credentials for both Consumers:

   ```yaml
   echo '
   apiVersion: v1
   kind: Secret
   metadata:
     name: admin-acl
     namespace: kong
     labels:
       konghq.com/credential: acl
   stringData:
     group: admin
   ---
   apiVersion: v1
   kind: Secret
   metadata:
     name: user-acl
     namespace: kong
     labels:
       konghq.com/credential: acl
   stringData:
     group: user
   ' | kubectl apply -f -
   ```

1. Patch the Consumers:

    ```bash
    kubectl patch -n kong --type json kongconsumer my-admin \
      -p='[{
        "op":"add",
        "path":"/credentials/-",
        "value":"admin-acl"
      }]'
    kubectl patch -n kong --type json kongconsumer my-user \
      -p='[{
        "op":"add",
        "path":"/credentials/-",
        "value":"user-acl"
      }]'
    ```

## Add access control

Based on our authorization policies, anyone can access `/secured-endpoint`, but only administrators can access `/sensitive-endpoint`.

1. Create an ACL plugin that allows requests from anyone in the `admin` or `user` groups to `/secured-endpoint`:

{% entity_example %}
type: plugin
data:
  name: anyone-acl
  plugin: acl
  config:
    allow:
      - admin
      - user
  route: secured-endpoint
indent: 4
{% endentity_example %}

1. Create an ACL plugin that allows requests from anyone in the `admin` group to `/sensitive-endpoint`:

{% entity_example %}
type: plugin
data:
  name: admin-acl
  plugin: acl
  config:
    allow:
      - admin

  route: sensitive-endpoint
indent: 4
{% endentity_example %}

## Validate your configuration

Your Routes are now protected with the Key Auth and ACL plugins using the following logic:

* If the `apikey` header is invalid, the `key-auth` plugin rejects the request
* If the identified Consumer has the `user` group in the ACL credential, they can access `/secured-endpoint`
* If the identified Consumer has the `admin` group in the ACL credential, they can access both `/secured-endpoint` and `/sensitive-endpoint`

Test the ACL plugin using the following requests:

1. `my-admin` can access `/secured-endpoint`:

{% validation request-check %}
url: '/secured-endpoint'
status_code: 200
headers:
  - apikey:my-admin-password
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
indent: 4
{% endvalidation %}

1. `my-user` can access `/secured-endpoint`:

{% validation request-check %}
url: '/secured-endpoint'
status_code: 200
headers:
  - apikey:my-user-password
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
indent: 4
{% endvalidation %}

1. `my-admin` can access `/sensitive-endpoint`:

{% validation request-check %}
url: '/sensitive-endpoint'
status_code: 401
headers:
  - apikey:my-admin-password
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
indent: 4
{% endvalidation %}

1. `my-user` can't access `/sensitive-endpoint`:

{% validation request-check %}
url: '/sensitive-endpoint'
status_code: 401
headers:
  - apikey:my-user-password
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
message: "You cannot consume this service"
indent: 4
{% endvalidation %}