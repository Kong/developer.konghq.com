---
title: Get started with {{site.konnect_short_name}} Identity
content_type: how_to
breadcrumbs:
  - /kong-identity/

permalink: /kong-identity/get-started/

tech_preview: true

products:
    - gateway
works_on:
  - konnect
tags:
    - get-started
description: Use this tutorial to get started with Kong IDP.

tldr: 
  q: How do I configure Kong Identity?
  a: | 
    Get started with Kong Identity by setting up an Authorization Server, Claims, Scopes and clients, then configuring the OpenID Connect plugin in a {{site.konnect_short_name}} Control Plane using the APIs.

tools:
    # - konnect-api
    - deck
  
prereqs:
  inline: 
    - title: "{{site.konnect_short_name}} Labs"
      content: |
        {{site.konnect_short_name}} Labs is a program for people to experiment with early-stage {{site.konnect_short_name}} experiences. Kong Identity can be opted in through {{site.konnect_short_name}} Labs. 
        You can view [Labs](https://cloud.konghq.com/global/labs/) in {{site.konnect_short_name}} 
      icon_url: /assets/icons/world.svg
  entities:
    services:
      - example-service
    routes:
      - example-route


automated_tests: false
related_resources:
  - text: "Kong Identity"
    url: /kong-identity/
  - text: Dynamic Templating
    url: /kong-identity/dynamic-templates/
---


## Create an auth server in Kong Identity with the appropriate audience
It is recommended to have different auth servers for different env or different subsidiaries. Auth Server name is unique per org, per Konnect region. Auth Server ID, Issuer and `metadata_url` is generated as part of the response

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers
status_code: 200
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "Appointments Dev"
  audience: "http://myhttpbin.dev"
  description: "auth server for Appointment dev environment"
{% endkonnect_api_request %}

Export the auth server ID and issuer URL:
```sh
export AUTH_SERVER_ID='YOUR-AUTH-SERVER-ID'
export ISSUER_URL='YOUR-ISSUER-URL'
```


## Configure the auth server with scopes and custom claims 
Advanced settings also enable dynamic custom claims. Claim ID and Scope ID are generated as part of the response. Scope names are unique per auth server. Claims are not unique.

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/scopes 
status_code: 200
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: "Scope"
  description: "Scope Description"
  default: false
  include_in_metadata: false
  enabled: true
{% endkonnect_api_request %}
<!--vale on-->

Export your scope ID:
```sh
export SCOPE_ID='YOUR-SCOPE-ID'
```

Configure your claim:

<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/claims 
status_code: 200
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: Claim
  value: Claim Value
  include_in_token: true
  include_in_all_scopes: false
  include_in_scopes: 
  - $SCOPE_ID
  enabled: true

{% endkonnect_api_request %}
<!--vale on-->


## Create a client in the Auth Server
Client is the machine to machine credential. Client has a “grant type” that can take values of `client_credentials`, implicit, `authorization_code`. An existing Client ID and Client Secret can be imported in the auth server. A client ID and client secret can also be automatically be created for the client. Token duration (in seconds) is configured per client


<!--vale off-->
{% konnect_api_request %}
url: /v1/auth-servers/$AUTH_SERVER_ID/clients
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: Client
  grant_types:
    - client_credentials
  allow_all_scopes: false
  allow_scopes:
    - $SCOPE_ID
  redirect_uris:
    - https://client.com/callback
  login_uri: https://client.com/login
  access_token_duration: 3600
  id_token_duration: 3600
  response_types:
    - id_token
    - token
{% endkonnect_api_request %}
<!--vale on-->

Export your client secret and client ID:
```sh
export CLIENT_SECRET='YOUR-CLIENT-SECRET'
export CLIENT_ID='YOUR-CLIENT-ID'
```

## Apply OpenID Connect plugin to a Control plane using Kong Identity as the IdP
You can use the OIDC plugin to use Kong Identity as the identity provider for your GW services. Apply an OIDC plugin to the control plane at a Global scope. This plugin can be applied at a Service level as well. Add the issuer generated in the auth server in the OIDC Issuer field. 

First, get the ID of the `quickstart` control plane you configured in the prerequisites:

curl -X GET "https://us.api.konghq.com/v2/control-planes?filter%5Bname%5D%5Bcontains%5D=quickstart" \
     -H "Authorization: Bearer $KONNECT_TOKEN"

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes?filter%5Bname%5D%5Bcontains%5D=quickstart
status_code: 201
method: GET
{% endkonnect_api_request %}
<!--vale on-->

Export the control plane ID:
```sh
export CONTROL_PLANE_ID='YOUR-CONTROL-PLANE-ID'
```

Enable the OIDC plugin globally:
<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/plugins/
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: openid-connect
  config:
    issuer: $ISSUER_URL
    client_id: 
    - $CLIENT_ID
    client_secret:
    - $CLIENT_SECRET
    client_auth:
    - client_secret_post
    auth_methods:
    - client_credentials
    audience:
    - http://myhttpbin.dev
    client_credentials_param_type:
    - header
{% endkonnect_api_request %}
<!--vale on-->

In this example:
* `issuer`, `client ID`, `client secret`, and `client auth`: Settings that connect the plugin to your IdP (in this case, {{site.konnect_short_name}} Identity). 
* `auth_methods`: Specifies that the plugin should use client credentials (client ID and secret) for authentication.
* `client_credentials_param_type`: Restricts client credential lookup to request headers only.

## Generate a token for the client
Generate a token for the client by making a call to the issuer URL. Use this generated token to access the GW service.

<!--vale off-->
```sh
curl -X POST "$ISSUER_URL/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "scope=Scope"
```
<!--vale on-->

## Access the Gateway service using the token 
Access the Gateway Service using the short lived token generated by the authorization server from Kong Identity
