title: How To Add an Admin Via API
content_type: how_to
related_resources:
  - text: Rate Limiting
    url: /rate-limiting/
  - text: How to create rate limiting tiers with {{site.base_gateway}}
    url:  /how-to/add-rate-limiting-tiers-with-kong-gateway/
  - text: Rate Limiting plugin
    url: /plugins/rate-limiting/
  - text: Rate Limiting Advanced plugin
    url: /plugins/rate-limiting-advanced/

description: How to generate an admin via API instead of Kong manager


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

plugins:
  - rate-limiting
  - key-auth

entities: 
  - service
  - plugin
  - consumer

tags:
    - admin-api

tldr:
    q: How to generate an admin via API instead of using Kong manager?
    a: Using Kong admin API to create a super-admin role and register a user as an admin.

tools:
    - admin-api

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Disable RBAC 
Disable rbac
## Create a super-admin user


Create an RBAC username
curl --request POST \  --url http://localhost:8001/rbac/users \  --header 'content-type: application/json' \  --data '{\n    "name":"JPK1",\n    "user_token":"JPK1"\n}'
 
Assign that user super-admin roles
curl --request POST \   --url http://localhost:8001/rbac/users/JPK1/roles \ --header 'content-type: application/json' \  --data '{\n    "roles":"super-admin"\n}'

## Re-enable RBAC 
 
Re Enable RBAC
With token "JPK1", create the admin
curl --request POST \
  --url http://localhost:8001/admins \
  --header 'content-type: application/json' \
  --header 'kong-admin-token: JPK1' \  --data '{"username":"test@gmail.com", "email":"test@gmail.com"}'




# Role assignment and token registration 
 
Assign admin a role
curl --request POST \
  --url http://localhost:8001/admins/8e7963fb-3a43-445a-975f-1f161c1e98a0/roles \
  --header 'content-type: application/json' \
  --header 'kong-admin-token: JPK1' \  --data '{"roles":"super-admin"}'

 
Generate registration token
curl --request GET \
  --url 'http://localhost:8001/default/admins/test@gmail.com?generate_register_url=true' \  --header 'kong-admin-token: JPK1'

 
Copy token from point 7 and register the admin
curl --request POST \
  --url http://localhost:8001/admins/register \
  --header 'content-type: application/json' \
  --header 'kong-admin-token: JPK1' \   --data '{"email":"test@gmail.com","username":"test@gmail.com","password":"test", "token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1NjQzNTEzMDYsImlkIjoiMzliMDY1OTMtZWY3My00MDQ3LTk3MjEtOTVjNjkzMjUxYzQ3In0.3xByXc3FJg67fCFQHX29ide24jYoGAhxjmFlCiA8vUs"}'
