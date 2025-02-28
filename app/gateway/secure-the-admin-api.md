---
title: Secure the Admin API
content_type: reference
layout: reference

products:
    - gateway

tools:
  - deck

description: placeholder

related_resources:
  - text: "Secure {{site.base_gateway}}"
    url: /gateway/security/
  - text: "{{site.base_gateway}} Admin API"
    url: /admin-api/
  - text: "Enable RBAC with the Admin API"
    url: /how-to/enable-rbac-with-admin-api/
---

{{site.base_gateway}}’s Admin API provides a RESTful interface for administration and configuration of Gateway Services, Routes, Plugins, Consumers, and credentials. Because this API allows full control of {{site.base_gateway}}, it's important to secure it against unwanted access. This document describes a few possible approaches to securing the Admin API.

## Network layer access restriction

Using the `admin_listen` parameter in the [{{site.base_gateway}} configuration](/gateway/configuration/), you can restrict access to the Admin to certain IPs.

### Minimal listening footprint

By default, {{site.base_gateway}} only accepts requests from the local interface (`127.0.0.0:8001`). If you change this value, make sure to keep the listening footprint to a minimum to avoid exposing your Admin API to third-parties, which could seriously compromise the security of your whole Kong cluster. For example, avoid using values such as `0.0.0.0:8001`.

### Layer 3/4 network controls

In cases where the Admin API must be exposed beyond a local interface, the best practice is to restrict network-layer access as much as possible. Consider an environment in which {{site.base_gateway}} listens on a private network interface, but should only be accessed by a small subset of an IP range. In this case, host-based firewalls (e.g. iptables) are useful in limiting input traffic ranges. For example:

```sh
# assume that Kong is listening on the address defined below, defined as a
# /24 CIDR block, and only a select few hosts in this range should have access

grep admin_listen /etc/kong/kong.conf
admin_listen 192.0.2.3:8001

# explicitly allow TCP packets on port 8001 from the Kong node itself
# this is not necessary if Admin API requests are not sent from the node
iptables -A INPUT -s 192.0.2.3 -m tcp -p tcp --dport 8001 -j ACCEPT

# explicitly allow TCP packets on port 8001 from the following addresses
iptables -A INPUT -s 192.0.2.4 -m tcp -p tcp --dport 8001 -j ACCEPT
iptables -A INPUT -s 192.0.2.5 -m tcp -p tcp --dport 8001 -j ACCEPT

# drop all TCP packets on port 8001 not in the above IP list
iptables -A INPUT -m tcp -p tcp --dport 8001 -j DROP
```

Additional controls, such as similar ACLs applied at a network device level, are encouraged.

## API loopback

{{site.base_gateway}}’s routing design allows it to serve as a proxy for the Admin API itself. You can use {{site.base_gateway}} to provide fine-grained access control to the Admin API. To do this, you need to bootstrap a new Gateway Service that defines the `admin_listen` address as the Service’s url.

For example, let’s assume that {{site.base_gateway}}'s `admin_listen` parameter is set to `127.0.0.1:8001`, so it is only available from localhost. The port `8000` is serving proxy traffic, exposed via `myhost.dev:8000`.

We want to expose Admin API via the url `:8000/admin-api`, in a controlled way. We can do so by creating a Service and Route for it inside `127.0.0.1`:

{% entity_examples %}
entities:
  services:
  - name: admin-api
    url: http://127.0.0.1:8001
  routes:
  - name: admin-api
    service: 
      name: admin-api
    paths:
    - /admin-api
{% endentity_examples %}

We can now reach the Admin API through the proxy server:
```sh
curl myhost.dev:8000/admin-api/services
```

Once the Service and Route are set up, you can apply security plugins as you would for any API. You can configure [authentication](/plugins/?category=authentication), [IP restriction](/plugins/ip-restriction/), or [access control lists](/plugins/acl/). For example:

{% entity_examples %}
entities:
  plugins:
  - name: key-auth
    service: admin-api
  consumers:
  - username: admin
    keyauth_credentials:
    - key: secret
{% endentity_examples %}

With this configuration, the Admin API will be available through `/admin-api`, but only for requests containing the `?apikey=secret` query parameter.

## Custom Nginx configuration

{{site.base_gateway}} is tightly coupled with Nginx as an HTTP daemon, and can be integrated into environments with custom Nginx configurations. Use cases with complex security and access control requirements can use the full power of Nginx and OpenResty to build server/location blocks to house the Admin API as necessary. This allows such environments to leverage native Nginx authorization and authentication mechanisms, ACL modules, etc., in addition to providing the OpenResty environment on which custom and complex security controls can be built.

For more information on integrating Kong into custom Nginx configurations, see the [Nginx configuration directives](/gateway/configuration/).

## Role-Based Access Control

You can configure [RBAC](/gateway/entities/rbac/) to secure access to the Admin API. RBAC allows for fine-grained control over resource access based on a model of user roles and permissions. Users are assigned to one or more roles, which possess one or more permissions granting or denying access to a particular resource. You can enforce fine-grained control over specific Admin API resources, while scaling to allow complex, case-specific uses.