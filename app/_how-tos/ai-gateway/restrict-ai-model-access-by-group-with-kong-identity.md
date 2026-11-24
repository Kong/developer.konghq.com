---
title: Restrict AI Model access to a group of {{site.identity}} principals
permalink: /ai-gateway/restrict-ai-model-access-by-group-with-kong-identity/
content_type: how_to
description: Use the Access Policy Engine and an access rule to let one group of {{site.identity}} principals call an AI Model while rejecting every other principal.

products:
  - ai-gateway
  - identity

works_on:
  - konnect

min_version:
  ai-gateway: '2.4'

entities:
  - ai-auth-strategy
  - ai-model-provider
  - ai-model
  - ai-policy
  - principal

tags:
  - ai
  - authorization
  - kong-identity

tools:
  - konnect-api

tldr:
  q: How do I let only one group of {{site.identity}} principals call an AI Model?
  a: |
    Put the principals in a {{site.identity}} group, then create an `allow` access rule (ACL) that anchors the group to the AI Model's upstream model name.
    Add the [Access Policy Engine](/ai-gateway/access-policy-engine/) globally, and map the callers' credentials to {{site.identity}} principals with an [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/#principal-mapping).
    Requests from principals in the group are proxied to the model. Requests from every other principal are rejected with a `403`.

prereqs:
  inline:
    - title: OpenAI API key
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl
      icon_url: /assets/icons/openai.svg
    - title: "{{site.identity}} directory"
      include_content: prereqs/kong-identity-directory
      icon_url: /assets/icons/identity.svg

cleanup:
  inline:
    - title: Clean up the access rule
      include_content: md/identity/delete_acl
      icon_url: /assets/icons/identity.svg
    - title: Clean up {{site.identity}} resources
      include_content: md/identity/delete_directory
      icon_url: /assets/icons/identity.svg
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

related_resources:
  - text: Access Policy Engine
    url: /ai-gateway/access-policy-engine/
  - text: AI Auth Strategy entity
    url: /ai-gateway/entities/ai-auth-strategy/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: "{{site.identity}} principals"
    url: /identity/principals/
  - text: Identify AI Consumers on AI Model traffic with {{site.identity}}
    url: /ai-gateway/identify-ai-consumers-with-kong-identity/
---

## Create principals

In this guide, you'll let one group of {{site.identity}} [principals](/identity/principals/) call an [AI Model](/ai-gateway/entities/ai-model/), and reject every other principal.
You'll create two principals, an `employee` and a `contractor`, and put only the `employee` in a group called `employees`.
An access rule allows the `employees` group to call the model.
The [Access Policy Engine](/ai-gateway/access-policy-engine/) evaluates every request against that rule.

Create the principal for the employee:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  display_name: "employee-principal"
  description: "A member of the employees group"
extract_body:
  - name: 'id'
    variable: EMPLOYEE_PRINCIPAL_ID
capture:
  - variable: EMPLOYEE_PRINCIPAL_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Create the principal for the contractor:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  display_name: "contractor-principal"
  description: "A principal that is not in the employees group"
extract_body:
  - name: 'id'
    variable: CONTRACTOR_PRINCIPAL_ID
capture:
  - variable: CONTRACTOR_PRINCIPAL_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Add an API key to each principal

Clients authenticate to {{site.ai_gateway}} with an API key.
The AI Auth Strategy that you create later maps that key to its principal.

Create a key for the employee:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$EMPLOYEE_PRINCIPAL_ID/api-keys
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  type: v1
extract_body:
  - name: 'secret'
    variable: EMPLOYEE_KEY
capture:
  - variable: EMPLOYEE_KEY
    jq: ".secret"
{% endkonnect_api_request %}
<!--vale on-->

Create a key for the contractor:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/principals/$CONTRACTOR_PRINCIPAL_ID/api-keys
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  type: v1
extract_body:
  - name: 'secret'
    variable: CONTRACTOR_KEY
capture:
  - variable: CONTRACTOR_KEY
    jq: ".secret"
{% endkonnect_api_request %}
<!--vale on-->

## Create a group and add the employee

Create the `employees` group in the directory:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/groups
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: employees
  description: "Principals that can call the AI Model"
extract_body:
  - name: 'id'
    variable: GROUP_ID
capture:
  - variable: GROUP_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

Add only the employee principal to the group:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/groups/$GROUP_ID/membership
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  member:
    id: $EMPLOYEE_PRINCIPAL_ID
    type: principal
{% endkonnect_api_request %}
<!--vale on-->

## Create an access rule for the group

Create an access rule that allows the `employees` group to call `gpt-5-mini`.
Access rules are called ACLs in the {{site.konnect_short_name}} API.

The rule names the model that the provider serves, `gpt-5-mini`, not the name that clients send, which you set when you create the AI Model.

The Policy rejects every request unless an `allow` rule matches, so create the rule before you add the Policy.

<!--vale off-->
{% konnect_api_request %}
url: /v1/policies/acls
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  display_name: "employees-can-call-gpt-5-mini"
  anchor:
    type: group
    id: $GROUP_ID
    directory_id: $DIRECTORY_ID
  effect: allow
  resources:
    - type: Model
      name: gpt-5-mini
extract_body:
  - name: 'id'
    variable: ACL_ID
capture:
  - variable: ACL_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Get the directory name

The AI Auth Strategy references the directory by name.

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories
status_code: 200
method: GET
extract_body:
  - name: 'data.0.name'
    variable: DIRECTORY_NAME
capture:
  - variable: DIRECTORY_NAME
    jq: ".data[0].name"
{% endkonnect_api_request %}
<!--vale on-->

## Create an AI Auth Strategy and AI Model Provider

Create a `key-auth` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) with [{{site.identity}} principal mapping](/ai-gateway/entities/ai-auth-strategy/#principal-mapping) enabled, so that clients authenticate with their API key and {{site.ai_gateway}} resolves each one to its principal.
You can't combine principal mapping with `identity_realms`, so set `identity_realms` to an empty list.

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/auth-strategies
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: identity-principal
  display_name: Identity Principal
  type: key-auth
  config:
    identity_realms: []
    principals:
      enabled: true
      directory: $DIRECTORY_NAME
{% endkonnect_api_request %}
<!--vale on-->

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) for OpenAI:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/model-providers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: generic-openai
  display_name: generic-openai
  type: openai
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: $OPENAI_AUTH_HEADER
{% endkonnect_api_request %}
<!--vale on-->

## Create an AI Model

Create an [AI Model](/ai-gateway/entities/ai-model/) that uses the AI Auth Strategy to authenticate clients.
Clients call the model as `my-gpt-5-mini`, and the target forwards the request to OpenAI as `gpt-5-mini`.

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/models
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: my-gpt-5-mini
  display_name: my-gpt-5-mini
  type: model
  enabled: true
  formats:
    - type: openai
  access:
    auth_strategies:
      - identity-principal
  config:
    route:
      paths:
        - /
      model:
        body_param: model
        values:
          - my-gpt-5-mini
  capabilities:
    - generate
  targets:
    - name: gpt-5-mini
      provider: generic-openai
      config:
        type: openai
{% endkonnect_api_request %}
<!--vale on-->

## Add the Access Policy Engine

Create an Access Policy Engine Policy with `global: true`.
It only supports global scope, so you don't attach anything to the AI Model, and it doesn't have configuration of its own.

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/policies
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  name: access-policy-engine
  display_name: Access Policy Engine
  type: access-policy-engine
  enabled: true
  global: true
  config: {}
{% endkonnect_api_request %}
<!--vale on-->

## Validate

1. Send a request with the employee's API key.
   The employee is in the `employees` group, so the `allow` rule matches and the request succeeds:

   <!--vale off-->
{% validation request-check %}
url: /chat/completions
method: POST
headers:
  - "apikey: $EMPLOYEE_KEY"
  - 'Content-Type: application/json'
body:
  model: my-gpt-5-mini
  messages:
    - role: user
      content: What is the capital of France?
status_code: 200
indent: 3
{% endvalidation %}
   <!--vale on-->

1. Send the same request with the contractor's API key.
   The contractor isn't in the group, so no `allow` rule matches and the Policy rejects the request:

   <!--vale off-->
{% validation request-check %}
url: /chat/completions
method: POST
display_headers: true
headers:
  - "apikey: $CONTRACTOR_KEY"
  - 'Content-Type: application/json'
body:
  model: my-gpt-5-mini
  messages:
    - role: user
      content: What is the capital of France?
status_code: 403
indent: 3
{% endvalidation %}
   <!--vale on-->

   The Policy returns its default rejection response:

   ```json
   {"message":"Forbidden"}
   ```
   {:.no-copy-code}
