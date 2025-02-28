---
title: Use the ACL plugin with Consumer Groups in {{site.base_gateway}}
content_type: how_to
  
products:
    - gateway

works_on:
    - on-prem
    - konnect

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
        - other-example-route

min_version:
  gateway: '3.4'

plugins:
  - acl
  - key-auth

entities:
  - consumer
  - consumer-group

tier: enterprise

tags:
  - security
  - traffic-control

tldr:
  q: How can I use the ACL plugin to restrict access to a Consumer Group?
  a: |
    Enable an authentication plugin, create Consumer Groups and Consumers, then enable the ACL plugin and use the `config.allow` to allow access to the Consumer Groups.
    

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## 1. Enable key authentication

The ACL plugin requires an authentication plugin. In this example, we'll use the [Key Auth plugin](/plugins/key-auth/) plugin, but you can use any Kong authentication plugin.

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      config:
        key_names:
          - apikey
{% endentity_examples %}

## 2. Create Consumer Groups

Let's create two Consumer Groups named `dev` and `admin`. These groups will be used to configure access to the Routes we created in the prerequisites.

{% entity_examples %}
entities:
  consumer_groups:
    - name: dev
    - name: admin
{% endentity_examples %}

## 3. Create Consumers

Create Consumers with credentials and assign each of them to a Consumer Group. For this example we'll create one Consumer for each Consumer Group.

{% entity_examples %}
entities:
  consumers:
    - username: Amal
      groups:
        - name: admin
      keyauth_credentials:
        - key: amal
    - username: Dana
      groups:
        - name: dev
      keyauth_credentials:
        - key: dana
{% endentity_examples %}

## 4. Enable the ACL plugin

Enable the ACL plugin for each Route and use the `config.allow` parameter to allow access to the Consumer Groups. We'll give the `admin` Consumer Group access to both Routes, but the `dev` group will only have access to `other-example-route`.

{% entity_examples %}
entities:
  plugins:
    - name: acl
      route: example-route
      config:
        include_consumer_groups: true
        allow:
        - admin
    - name: acl
      route: other-example-route
      config:
        include_consumer_groups: true
        allow:
        - admin
        - dev
{% endentity_examples %}

## 5. Validate

Send requests to both Routes with the two API keys to validate that the access restrictions work as expected.

With the API key `amal`, we can access both Routes:

{% validation request-check %}
url: '/anything'
status_code: 200
headers:
  - 'apikey:amal'
{% endvalidation %}

{% validation request-check %}
url: '/anything/else'
status_code: 200
headers:
  - 'apikey:amal'
{% endvalidation %}

With the API key `dana`, we can only access `/anything/else`:

{% validation request-check %}
url: '/anything'
status_code: 403
headers:
  - 'apikey:dana'
{% endvalidation %}

{% validation request-check %}
url: '/anything/else'
status_code: 200
headers:
  - 'apikey:dana'
{% endvalidation %}