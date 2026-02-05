---
title: Use the ACL plugin with Consumer Groups in {{site.base_gateway}}
permalink: /how-to/use-acl-with-consumer-groups/
content_type: how_to
description: Restrict access to your resources based on Consumer Groups with the ACL plugins.   
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
        - delete-route
        - no-delete-route

min_version:
  gateway: '3.4'

plugins:
  - acl
  - key-auth

entities:
  - consumer
  - consumer-group

tags:
  - security
  - traffic-control

tldr:
  q: How can I use the ACL plugin to restrict access to a Consumer Group?
  a: |
    Enable an [authentication plugin](/plugins/?category=authentication), create [Consumer Groups](/gateway/entities/consumer-group/) and [Consumers](/gateway/entities/consumer/), then enable the [ACL plugin](/plugins/acl/) and use the `config.allow` to allow access to the Consumer Groups.
    

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Enable key authentication

The ACL plugin requires an authentication plugin. In this example, we'll use the [Key Auth plugin](/plugins/key-auth/) plugin, but you can use any authentication plugin.

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      config:
        key_names:
          - apikey
{% endentity_examples %}

## Create Consumer Groups

Let's create two Consumer Groups named `dev` and `admin`. These groups will be used to configure access to the Routes we created in the prerequisites.

{% entity_examples %}
entities:
  consumer_groups:
    - name: dev
    - name: admin
{% endentity_examples %}

## Create Consumers

Create Consumers with credentials and assign each of them to a Consumer Group.

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

## Enable the ACL plugin

Enable the ACL plugin for each Route and use the `config.allow` parameter to allow access to the Consumer Groups. We'll give the `admin` Consumer Group access to both Routes, but the `dev` group will only have access to `no-delete-route`. This means that only the `admin` group will be able to use the `DELETE` method on the `/anything` endpoint.

{% entity_examples %}
entities:
  plugins:
    - name: acl
      route: delete-route
      config:
        include_consumer_groups: true
        allow:
        - admin
    - name: acl
      route: no-delete-route
      config:
        include_consumer_groups: true
        allow:
        - admin
        - dev
{% endentity_examples %}

## Validate

Send requests to both Routes with the two API keys to validate that the access restrictions work as expected.

With the API key `amal`, we can send `GET`, `POST`, `PUT`, and `DELETE` requests to the `/anything` endpoint:

{% validation request-check %}
url: '/anything'
status_code: 200
method: POST
headers:
  - 'apikey:amal'
{% endvalidation %}

{% validation request-check %}
url: '/anything'
status_code: 200
method: DELETE
headers:
  - 'apikey:amal'
{% endvalidation %}

With the API key `dana`, we can't send `DELETE` requests:
{% validation request-check %}
url: '/anything'
status_code: 403
method: DELETE
headers:
  - 'apikey:dana'
{% endvalidation %}
