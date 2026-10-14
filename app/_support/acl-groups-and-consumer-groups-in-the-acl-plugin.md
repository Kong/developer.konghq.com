---
title: ACL groups and Consumer Groups in the ACL plugin
content_type: support
description: Explains the difference between ACL groups and Consumer Groups when used with the ACL plugin, and how to combine them by setting `include_consumer_groups`.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: information about consumer groups
    url: /gateway/entities/consumer-group/
tldr:
  q: What's the difference between ACL groups and Consumer Groups in the ACL plugin?
  a: |
    ACL groups are set directly on a consumer's `acls` property. Consumer Groups are a separate core entity that a consumer joins through its `groups` property, letting you manage and scope plugins to many consumers at once instead of individually.

    By default, the ACL plugin's allow/deny list only checks ACL groups. Set `include_consumer_groups: true` on the ACL plugin to also let Consumer Group names appear in that list. Consumer Groups can also be used to scope other plugins, such as `rate-limiting-advanced`, to just that group of consumers.
---

## Problem

ACL groups and Consumer Groups can both be referenced in the ACL plugin's allow/deny list, but it's not clear how the two differ or how to use them together.

## Solution

The Kong ACL plugin uses the ACL groups configured in the consumer to decide if the consumer is allowed or denied. In a declarative config, an ACL group is defined in the consumer as:

```yaml

consumers:
- username: first_consumer
  acls: 
    - group: acl_group
  keyauth_credentials:
  - key: consumer1
```

So the acl plugin can be configured to allow / deny all consumers that belong to an ACL group :

```yaml

plugins:
- name: acl
  service: anything
  config:
    allow:
    - acl_group
```

The ACL plugin allows you to configure consumer_groups in the allow / deny list by using the config setting `include_consumer_groups: true`

A `consumer_group` is a new Kong core entity to group consumers within an API ecosystem. By grouping consumers together, you eliminate the need to manage them individually, providing a scalable, efficient approach to managing configurations.

With consumer groups, you can scope plugins to specifically defined consumer groups and a new plugin instance will be created for each individual consumer group, making configurations and customizations more flexible and convenient.

To define `consumer_groups` in a declarative config, you first need to define the `consumer_groups` entities:

```yaml

consumer_groups:
- name: green_consumer_group
- name: red_consumer_group
```

To add relationships between consumers and `consumer_groups` can be done in the consumer's `groups` property:

```yaml

consumers:
- username: second_consumer
  groups:
  - name: green_consumer_group
  keyauth_credentials:
  - key: consumer2
```

So now, the `second_consumer` does not belong to any ACL group but belongs to the `green_consumer_group` consumer_group.

The `green_consumer_group` name can also be used in ACL plugin configuration allow / deny list if you set the `include_consumer_groups: true`

```yaml

plugins:
- name: acl
  service: anything
  config:
    include_consumer_groups: true
    allow:
    - acl_group 
    - green_consumer_group
```

This is useful if you require to scope some other plugin to the consumer_group like a `rate-limiting-advanced` plugin:

```yaml

plugins:
- name: rate-limiting-advanced
  service: anything
  consumer_group: green_consumer_group
  config: 
    window_size:
      - 10
    limit:
      - 2
    identifier: consumer
    sync_rate: -1
    namespace: example_namespace
    strategy: local
```

Find below a full declarative config where:

- `first_consumer` belongs to an ACL group
- `second_consumer` belongs to a `consumer_group`, this `consumer_group` has also a `rate-limiting-advanced` plugin configured
- `third_consumer` belongs to a `consumer_group` which is not allowed in the acl plugin

```yaml

_format_version: "3.0"

# Define 2 consumer groups
consumer_groups:
- name: green_consumer_group
- name: red_consumer_group

consumers:
# This consumer does not belong to any consumer_group, but it has a an ACL group configured:
- username: first_consumer
  acls: 
    - group: acl_group
  keyauth_credentials:
  - key: consumer1

# This consumer belongs to green_consumer_group:
- username: second_consumer
  groups:
  - name: green_consumer_group
  keyauth_credentials:
  - key: consumer2

# This consumer belongs to red_consumer_group:
- username: third_consumer
  groups:
  - name: red_consumer_group
  keyauth_credentials:
  - key: consumer3

# Sample httpbin.org service with a /anything route:
services:
- host: httpbin.org
  name: anything
  path: /anything
  port: 80
  protocol: http

  routes:
  - name: anything
    protocols:
    - http
    - https
    paths: 
    - /anything

plugins:
# Key-Auth pluguin to authenticate consumers
- name: key-auth
  service: anything
  config:
    key_names:
    - apikey

# The acl plugin can either reference ACL groups or consumer_groups (if include_consumer_groups is set to true)
- name: acl
  service: anything
  config:
    include_consumer_groups: true
    allow:
    - acl_group 
    - green_consumer_group

# Consumer Groups are useful to add more plugins like Rate-Limiting-Advanced scoped to a set of consumers
- name: rate-limiting-advanced
  service: anything
  consumer_group: green_consumer_group
  config: 
    window_size:
      - 10
    limit:
      - 2
    identifier: consumer
    sync_rate: -1
    namespace: example_namespace
    strategy: local
```

First consumer request, allowed with no rate-limiting:

```bash

curl -I  http://localhost:8000/anything -H "apikey:consumer1"
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 779
Connection: keep-alive
Date: Wed, 09 Oct 2024 08:12:30 GMT
Server: gunicorn/19.9.0
Access-Control-Allow-Origin: *
Access-Control-Allow-Credentials: true
X-Kong-Upstream-Latency: 186
X-Kong-Proxy-Latency: 1
Via: 1.1 kong/3.14.0.0-enterprise-edition
X-Kong-Request-Id: 5f80954be4b5175a070efb5f18a03643
```

Second consumer request: allowed with rate-limiting:

```bash

curl -I  http://localhost:8000/anything -H "apikey:consumer2"
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 791
Connection: keep-alive
X-RateLimit-Limit-10: 2
X-RateLimit-Remaining-10: 1
RateLimit-Remaining: 1
RateLimit-Reset: 3
RateLimit-Limit: 2
Date: Wed, 09 Oct 2024 08:12:47 GMT
Server: gunicorn/19.9.0
Access-Control-Allow-Origin: *
Access-Control-Allow-Credentials: true
X-Kong-Upstream-Latency: 423
X-Kong-Proxy-Latency: 1
Via: 1.1 kong/3.14.0.0-enterprise-edition
X-Kong-Request-Id: 87b7900e985f0f180bfdde1329fc3755
```

Third consumer request: denied

```bash

curl -I  http://localhost:8000/anything -H "apikey:consumer3"
HTTP/1.1 403 Forbidden
Date: Wed, 09 Oct 2024 08:13:39 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Content-Length: 100
X-Kong-Response-Latency: 0
Server: kong/3.14.0.0-enterprise-edition
X-Kong-Request-Id: dad576664b047e6d692cdd33c931c842
```
