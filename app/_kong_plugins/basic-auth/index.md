---
title: Basic Auth

name: Basic Auth
publisher: kong-inc
content_type: plugin
description: Secure Services and Routes with Basic Authentication
tags:
    - authentication

products:
    - gateway

works_on:
    - on-prem
    - konnect

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: basic-auth.png

categories:
  - authentication

search_aliases:
  - basic-auth
  - username and password auth

faqs:
  - q: I updated my Consumer's username, why doesn't their password or basic authentication work anymore?
    a: The basic auth password credential is encrypted in the database. {{site.base_gateway}} can only get the encrypted value of the password from the database. When you update the username or tag, {{site.base_gateway}} overwrites the password with its encrypted value. To fix this, enter the original password when you update the username or tag of the basic auth credential.
  - q: How do I delete a Consumer credential?
    a: You can delete a specific credential by sending a `DELETE` request to `/{workspace_id_or_name}/consumers/{consumer_id_or_name}/basic-auth/{credentials_id}`.
  - q: I'm migrating from {{site.base_gateway}} to {{site.konnect_short_name}} and using `deck gateway dump`, will this also dump my basic auth credentials?
    a: No. The basic auth credentials are stored in the database as hashed values. When you dump the configuration with decK, it will retrieve these hashed values, not the original plain-text passwords. Since there is currently no way to extract the initial plain-text values of the basic auth credentials due to how they are stored, you will need to manually set the passwords for basic auth after dumping the configuration or by directly setting up the password in {{site.konnect_short_name}}.
  - q: Why should I use the Basic Authentication plugin instead of other authentication plugins, like Key Authentication?
    a: You should use basic authentication when you need a simple way to authenticate and security isn't a concern. For example, you could use this plugin to connect internal server networks or as a verification on open data. Use Key Authentication or another authentication plugin if you require additional security.

related_resources:
  - text: Basic Auth how-to guides
    url: /how-to/?query=basic-auth

min_version:
  gateway: '1.0'
---

The [Basic Authentication](https://datatracker.ietf.org/doc/html/rfc7617 ) plugin enforces username and password authentication for [Consumers](/gateway/entities/consumer/) when making a request to a [Gateway Service](/gateway/entities/service/) or [Route](/gateway/entities/route/). Consumers represent a developer or an application consuming the upstream service. 

Basic authentication can be used with both HTTP and HTTPS requests and is an effective way to add simple password protection to web applications.

## How it works

The Basic Authentication plugin requires at least one Consumer to work. When you create the Consumer, you must specify a username and password, for example: `Ariel:Password`. The Consumer's password must be base64-encoded when it's used in the Authentication header. For example, `Ariel:Password` would become `QXJpZWw6UGFzc3dvcmQ=`.

Then, you can enable the plugin on a Gateway Service, Route, or globally. When a Consumer makes a request to the associated Gateway Service or Route, the plugin checks for valid credentials in the `Proxy-Authorization` and `Authorization` headers (in that order). In {{site.base_gateway}} 3.13 or later, you can [protect against brute force attacks](#brute-force-protection) by enabling `config.brute_force_protection`. This will return an `429 Too Many Requests` error after the fourth failed login attempt.

### Using multiple authentication plugins

You can use the Basic Authentication plugin along with other authentication plugins. This allows clients to use different authentication methods to access a given Gateway Service or Route. 

The authentication plugins can be configured to always require authentication or only perform authentication if the Consumer wasn't already authenticated. For more information, see [Using multiple authentication methods](/gateway/authentication/#using-multiple-authentication-methods).

## Use cases

Common use cases for the Basic Authentication plugin:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "Allow or deny requests on a Gateway Service or Route"
    description: "Configure both the [ACL](/plugins/acl/) and Basic Authentication plugins to restrict access to a Service or a Route by adding Consumers to allowed or denied lists using arbitrary ACL groups."
  - use_case: "Authenticate on the upstream service"
    description: "Configure the Basic Authentication plugin on a Route and then configure the Consumer credential in the `config.add.headers` property for the [Request Transformer](/plugins/request-transformer/) plugin."
  - use_case: "[Allow clients to choose their authentication method](/how-to/allow-multiple-authentication/)"
    description: "Enable the Basic Authentication plugin and any other authentication plugins. Use the `config.anonymous` property on the plugins to determine if authentication is always performed or only when the Consumer wasn't already authenticated."
  - use_case: "Check credentials per session"
    description: "When the [Session](/plugins/session/) plugin is enabled in conjunction with an authentication plugin, it runs before credential verification. If no session is found, then the authentication plugin runs again and credentials are checked normally. If the credential verification is successful, then the Session plugin creates a new session for usage with subsequent requests."
  - use_case: "Rate limit unauthenticated and authenticated users differently"
    description: "You can configure a given Service to allow both authenticated and anonymous access. You might use this configuration to grant access to anonymous users with a low rate limit and grant access to authenticated users with a higher rate limit using the [Rate Limiting](/plugins/rate-limiting/) plugin."
  - use_case: "Use basic authentication for Kong Manager"
    description: "If you want users to authenticate before logging in to Kong Manager, you can configure basic authentication for the GUI."
  - use_case: |
      Protect against brute force attacks {% new_in 3.13 %}
    description: |
      [Protect against brute force attacks](#brute-force-protection) by enabling `config.brute_force_protection`. This will return an `429 Too Many Requests` error after the fourth failed login attempt.
{% endtable %}
<!--vale on-->

## Brute force protection {% new_in 3.13 %}

The Basic Auth plugin can be susceptible to brute force and dictionary attacks because [rate limiting occurs *after* authentication plugins](/gateway/entities/plugin/#plugin-priority), leaving a vulnerability to failed login attempts. You can configure `config.brute_force_protection` on the plugin to prevent this.

This feature protects against brute force attacks by doing the following:
1. When brute force protection is enabled, the plugin tracks failed login attempts by username. 
1. For each failed login attempt using a username and password, a counter is incremented with the username as the key in the shared store. The plugin starts returning a `429 Too Many Requests` response on the 3rd failed login attempt. The 429 response includes a `Retry-After` header, which indicates the remaining Time-To-Live (TTL) of the counter for that username.
1. Each additional failed attempt doubles the previous wait time. The wait time is calculated as 2^(number of failed attempts) seconds, with a maximum configurable wait time of 1 hour. There is no cache to clear.

Keep the following limitations in mind when you configure brute force protection:
* Counters are only reset when their TTL is reached. A successful login attempt **does not** reset the failed attempt counter. The user will still be blocked until the TTL expires.
* There is no way to unlock a user. You can manually delete the counter key from Redis or PostgreSQL.
* If the Redis connection fails, the brute force protection will error out.
* Each backend has different impacts on performance. In-memory has the best performance, PostgreSQL the poorest, and Redis is better than PostgreSQL. 

{% include plugins/redis-cloud-auth.md %}
