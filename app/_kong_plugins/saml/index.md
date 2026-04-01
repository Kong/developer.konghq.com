---
title: 'SAML'
name: 'SAML'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Provides SAML v2.0 authentication and authorization between a service provider (Kong) and an identity provider (IdP)'


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.1'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: saml.png

categories:
  - authentication

tags:
  - saml
  - authentication

search_aliases:
  - azure
  - security assertion markup language

related_resources:
  - text: Enable SAML authentication for {{site.base_gateway}} using Microsoft Entra
    url: /how-to/enable-saml-authentication-with-microsoft-entra/
  - text: "{{site.base_gateway}} authentication"
    url: /gateway/authentication/

notes: |
  In Serverless gateways only the `cookie` config session storage is supported.
---

This plugin provides Security Assertion Markup Language (SAML) v2.0 authentication and authorization between {{site.base_gateway}} and an identity provider.

The SAML specification defines three roles:

* A principal
* An identity provider (IdP)
* A service provider (SP)

The SAML plugin acts as the SP and is responsible for
initiating a login to the IdP. This is called an SP Initiated Login.

The minimum configuration required is:

- An IdP certificate (`idp_certificate`): The SP needs to obtain the
  public certificate from the IdP to validate the signature. The
  certificate is stored on the SP and is used to verify that a response
  is coming from the IdP.
- The ACS Endpoint (`assertion_consumer_path`): This is the endpoint
  provided by the SP where SAML responses are posted. The SP needs
  to provide this information to the IdP.
- The IdP sign-in URL (`idp_sso_url`): This is the IdP endpoint where
  SAML will issue `POST` requests. The SP needs to obtain this
  information from the IdP.
- The issuer (`issuer`): This us the unique identifier of the IdP application.

The plugin currently supports SAML 2.0 with Microsoft Entra. Refer to the
[Microsoft Entra SAML documentation](https://learn.microsoft.com/en-us/entra/architecture/auth-saml)
for more information about SAML authentication with Azure AD.

## How the SAML plugin works

As the SP-initiated mode of SAML requires the client to authenticate
to the IdP using a web browser, the plugin is only useful when it's
used with a browser-based web application.

It's designed to intercept requests sent from the client to the
upstream to detect whether a session has been established by
authenticating with the IdP. If no session is found, the request is
redirected to the IdP's login page for authentication. Once the
user has successfully authenticated, the user is redirected to the
application and the original request is sent to the upstream
server.

The authentication process can only be initiated when the request is
coming from a web browser. The plugin determines this by matching
the request's `Accept` header. If it contains the string
`"text/html"`, the request is redirected to the IdP, otherwise it's
responded to with a `401 (Unauthorized)` status code.

The plugin initiates the redirection to the IdP's login page by
responding with an HTML form that contains the authentication
request details in hidden parameters and some JavaScript code to
automatically submit the form. This is needed because the
authentication parameters need to be transmitted to Microsoft Entra's SAML
implementation using a POST request, which cannot be done with a
HTTP redirect response.

The plugin supports initiating the IdP authentication flow from a
POST request, to support the use case that the session expires while
the user is filling out a web form. In such scenarios, the plugin
transmits the posted form parameters to the IdP in the `RelayState`
parameter in encrypted form. When the authentication process
finishes, the IdP sends the `RelayState` back to the plugin. After
decryption, the plugin then responds back to the web browser with
another automatically self-submitting form containing the original
form parameters as hidden parameters. This feature is only
available with forms that use `"application/x-www-form-urlencoded"` as
their content type. Forms that use `"text/plain"` or
`"multipart/form-data"` are not supported.

When the authentication process has finished, the plugin creates and
maintains a session inside of {{site.base_gateway}}. A cookie in the browser
is used to track the session. Data that is attached to the session
can be stored in Redis, Memcached, or in the cookie itself. 

{:.info}
> **Note**: The lifetime of the session that is created by the IdP needs
to be configured in the plugin.

## Troubleshooting the SAML plugin

You may have a valid certificate specified in the `idp_certificate` field, but you get the following error:

```
[saml] user is unauthorized with error: public key in saml response does not match
```

If you provide a certificate through the `idp_certificate` field, the certificate must have the header and footer removed.

For example, a standard certificate might look like this, with a header and footer:

```
-----BEGIN CERTIFICATE-----
<certificate contents>
-----END CERTIFICATE-----
```

Remove the header and footer before including the certificate in the `idp_certificate` field:
```
<certificate contents>
```

{% include plugins/redis-cloud-auth.md %}
