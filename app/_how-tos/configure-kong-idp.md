---
title: Get started with Kong IDP
content_type: how_to
breadcrumbs:
  - /kong-identity/

permalink: /kong-identity/get-started/

tech_preivew: true

products:
  - gateway

works_on:
  - konnect

tags:
    - get-started
description: Use this tutorial to get started with Kong IDP.

tldr: 
  q: ADD A TLDR here
  a: | 
    Get started with {{site.event_gateway}} by setting up a {{site.konnect_short_name}} Control Plane and a Kafka cluster, then configuring the Control Plane using the `/declarative_config` endpoint of the Control Plane Config API.

tools:
    - konnect-api
  


cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

automated_tests: false
related_resources:
  - text: "{{site.event_gateway_short}} configuration schema"
    url: /api/event-gateway/knep/
  - text: Event Gateway
    url: /event-gateway/
---


## Create an auth server in Kong Identity with the appropriate audience

<!--vale off-->
{% control_plane_request %}
url: /v1/auth-servers/$authServerId/clients/$clientId/test-claim
status_code: 200
method: POST
headers:
  - 'Authorization: Bearer $KONNECT_TOKEN'
  - 'Content-Type: application/json'
body:
  name: "Appointments Dev"
  audience: "http://myhttpbin.dev"
  description: "auth server for Appointment's dev environment"
{% endcontrol_plane_request %}
<!--vale on-->


## Configure the auth server with scopes and custom claims 


<!--vale off-->
{% control_plane_request %}
url: /v1/auth-servers/1234/scopes 
status_code: 200
method: POST
headers:
  - 'Authorization: Bearer $KONNECT_TOKEN'
  - 'Content-Type: application/json'
body:
  name: "Scope"
  description: "Scope Description"
  default: false
  include_in_metadata: false
  enabled: true
{% endcontrol_plane_request %}
<!--vale on-->


## Create a client in the Auth Server


<!--vale off-->
{% control_plane_request %}
url: /v1/auth-servers/1234/clients
status_code: 201
method: POST
headers:
  - 'Authorization: Bearer $KONNECT_TOKEN'
  - 'Content-Type: application/json'
body:
  name: Client
  grant_types:
    - client_credentials
  allow_all_scopes: false
  allow_scopes:
    - Scope
  redirect_uris:
    - https://client.com/callback
  login_uri: https://client.com/login
  access_token_duration: 3600
  id_token_duration: 3600
  response_types:
    - id_token
    - token
{% endcontrol_plane_request %}
<!--vale on-->


