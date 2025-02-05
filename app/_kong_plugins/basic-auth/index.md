---
title: Basic Auth

name: Basic Auth
publisher: kong-inc
content_type: plugin
description: Secure services and routes with Basic Authentication
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

faqs:
  - q: I updated my Consumer's username, why doesn't their password or basic authentication work anymore?
    a: The basic auth password credential is encrypted in the database. {{site.base_gateway}} can only get the encrypted value of the password from the database. When you update the username or tag, {{site.base_gateway}} overwrites the password with its encrypted value. To fix this, enter the original password when you update the username or tag of the basic auth credential.
  - q: How do I delete a Consumer credential?
    a: You can delete a specific credential by sending a `DELETE` request to `http(s)://<kong-host>:<admin-port>/consumers/<workspace>/<consumer_id_or_name>/<type of credentials>/<credentials_id_or_name>`.
  - q: I'm migrating from {{site.base_gateway}} to {{site.konnect_short_name}} and using `deck gateway dump`, will this also dump my basic auth credentials?
    a: No. The basic auth credentials are stored in the database as hashed values. When you dump the configuration with deck, it will retrieve these hashed values, not the original plain-text passwords. Since there is currently no way to extract the initial plain-text values of the basic auth credentials due to how they are stored, you will need to manually set the passwords for basic auth after dumping the configuration or by directly setting up the password in {{site.konnect_short_name}}. There is an ongoing feature request to change the behavior of how basic auth credentials are handled during migrations to make this process more seamless in the future.
  - q: Why should I use the Basic Authentication plugin instead of other authentication plugins, like Key Authentication?
    a: You should basic authentication when you need a simple way to authenticate and security isn't a concern. For example, you could use this to connect internal server networks or as a verification on open data. Use Key Authentication or another authentication plugin if you require additional security.
---

## Overview

The [Basic Authentication](https://datatracker.ietf.org/doc/html/rfc7617 ) plugin enforces username and password authentication for [Consumers](/gateway/entities/consumer/) when making a request to a [Gateway Service](/gateway/entities/service/) or [Route](/gateway/entities/route/). Consumers represent a developer or an application consuming the service application. 

Basic Authentication can be used with both HTTP and HTTPS requests and is an effective way to add simple password protection to web applications.

## How it works

The Basic Authentication plugin requires at least one Consumer to work. When you create the Consumer, you must specify a username and password, for example: `Ariel:Password`. The Consumer's password must be base64 encoded when it's used in the Authentication header. For example, `Ariel:Password` would become `QXJpZWw6UGFzc3dvcmQ=`.

Then, you can enable the plugin on a Gateway Service, Route, or globally. When a Consumer makes a request to the associated Gateway Service or Route, the plugin checks for valid credentials in the `Proxy-Authorization` and `Authorization` headers (in that order).

### Using multiple authentication plugins

You can use the Basic Authentication plugin along with other authentication plugins. This allows clients  to use different authentication methods to access a given Gateway Service or Route. 

The authentication plugins can be configured to always require authentication or only perform authentication if the Consumer wasn't already authenticated. For more information, see [Using multiple authentication methods](/gateway/authentication/#using-multiple-authentication-methods).

## Use cases

Common use cases for the Basic Authentication plugin:

|Use case | Description|
|---------|------------|
| [Allow or deny requests on a Gateway Service or Route](/how-to/allow-or-deny-requests-on-a-service-or-route/) | Configure both the [ACL](/plugins/acl/) and Basic Authentication plugins to restrict access to a Service or a Route by adding Consumers to allowed or denied lists using arbitrary ACL groups. |
| [Authenticate on the upstream service](/how-to/authenticate-on-the-upstream-service/) | Configure the Basic Authentication plugin on a Route and then configure the Consumer credential in the `config.add.headers` property for the Request Transformer plugin. |
| [Allow clients to choose their authentication method](/how-to/allow-multiple-authentication/) | Enable the Basic Authentication plugin and any other authentication plugins. Use the `config.anonymous` property on the plugins to determine if authentication is always performed or only when the Consumer wasn't already authenticated. |
| [Check credentials per session](/how-to/check-credentials-per-session/) | When the [Session](/plugins/session/) plugin is enabled in conjunction with an authentication plugin, it runs before credential verification. If no session is found, then the authentication plugin runs again and credentials are checked normally. If the credential verification is successful, then the Session plugin creates a new session for usage with subsequent requests. |
| [Prevent anonymous access](/how-to/prevent-anonymous-access/) | If you enable anonymous access so that authentication isn't always performed but you don't want unauthorized users to access the Gateway Service or Route, you can configure the [Request Termination](/plugins/request-termination/) plugin on the anonymous Consumer. If this isn't configured, it will allow unauthorized requests. |
| [Rate limit unauthenticated and authenticated users differently](/how-to/rate-limit-authenticated-and-unauthenticated-consumers/) | You can configure a given Service to allow both authenticated and anonymous access. You might use this configuration to grant access to anonymous users with a low rate limit and grant access to authenticated users with a higher rate limit. |
| [Use basic authentication for Kong Manager](/how-to/enable-basic-auth-on-kong-manager/) | If you want users to authenticate before logging in to Kong Manager, you can configure basic authentication for the GUI. | 


