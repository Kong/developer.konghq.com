---
title: RBAC
content_type: reference
products:
  - gateway
tiers: 
  - enterprise
tools:
    - admin-api
    - kic
    - deck
    - terraform
entities:
  - rbac
description: The RBAC entity is what allows for the RBAC system to be administered.
schema:
    api: gateway/admin-ee
    path: /schemas/rbac

related_resources:
  - text: Gateway Workspace entity
    url: /gateway/entities/workspace/
  - text: Gateway Vault entity
    url: /gateway/entities/vault/
---
@TODO





s
## Schema

{% entity_schema %}

## Set up a Route

{% entity_example %}
type: rbac
data:
  name: my-user
  user_token: exampletoken
{% endentity_example %}
