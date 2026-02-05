---
title: Configure a {{site.base_gateway}} RBAC user with custom permissions
permalink: /how-to/configure-rbac-user-in-kong-gateway/
content_type: how_to
description: Learn how to create a {{site.base_gateway}} RBAC user and configure it with roles and permissions.
products:
    - gateway

works_on:
    - on-prem

tags:
  - authorization
  - access-control
  - rbac

related_resources:
  - text: Gateway RBAC
    url: /gateway/entities/rbac/
  - text: Gateway Groups
    url: /gateway/entities/group/
  - text: Gateway Admins
    url: /gateway/entities/admin/
  - text: Gateway Workspaces
    url: /gateway/entities/workspace/
  - text: Create a Super Admin
    url: /how-to/create-a-super-admin/

tldr: 
  q: How do I configure a {{site.base_gateway}} user with a role and permissions?
  a: |
     To configure an RBAC user in {{site.base_gateway}}, create the user with the `/rbac/users` endpoint of the Admin API, create a custom role with endpoint permissions using `/rbac/roles`, then assign the role to the new user.

faqs:
  - q: When accessing a restricted resource with an RBAC user via the Admin API, why do I get `Invalid RBAC credentials` instead of a permissions error?
    a: If you see an `Invalid RBAC credentials` error, this means that the user token you provided is incorrect or doesn't exist. Check your credentials and try again.

rbac: true

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
  gateway: '3.4'
---

## Create an RBAC user

An RBAC user has the ability to access the {{site.base_gateway}} Admin API.
The permissions assigned to their role will define the types of actions they can perform with various Admin API objects.

Create an [RBAC](/gateway/entities/rbac/) user by sending a `POST` request to the [`/rbac/users`](/api/gateway/admin-ee/#/operations/post-rbac-users) endpoint:

<!-- vale off -->
{% control_plane_request %}
url: /rbac/users
method: POST
body:
    name: alex
    user_token: alex-token
headers:
    - 'Kong-Admin-Token:kong'
status_code: 201
{% endcontrol_plane_request %}
<!-- vale on -->

By omitting the Workspace in the request, the user gets added to the `default` Workspace.

## Create a role with endpoint permissions

Let's say that in our environment, we need a subset of users to access Gateway Services only. 
Create a new role:

{% control_plane_request %}
url: /rbac/roles
method: POST
headers:
  - 'Kong-Admin-Token:kong'
body:
  name: dev
status_code: 201
{% endcontrol_plane_request %}

Then, assign endpoint permissions to the role, allowing access **only** to the `/services` endpoint:

{% control_plane_request %}
url: /rbac/roles/dev/endpoints
method: POST
headers:
  - 'Kong-Admin-Token:kong'
body:
  endpoint: '/services/'
  workspace: default
  actions: 
    - '*'
status_code: 201
{% endcontrol_plane_request %}

## Assign role to user

Assign the `dev` role to the user you created earlier:

{% control_plane_request %}
url: /rbac/users/alex/roles
method: POST
headers:
  - 'Kong-Admin-Token:kong'
body:
  roles: dev
status_code: 201
{% endcontrol_plane_request %}

## Validate 

You can validate that the user has correct permissions by trying to access entities with the user's access token.
First, try to access `/routes`, which this user doesn't have permissions for:

{% control_plane_request %}
url: /routes
headers:
  - "Kong-Admin-Token:alex-token"
display_headers: true
status_code: 403
{% endcontrol_plane_request %}

If RBAC was enabled correctly, this request returns the following error message:

```
{"message":"alex, you do not have permissions to read this resource"}%          
```
{:.no-copy-code}

Now, try adding a Service using the `/services` endpoint: 

{% control_plane_request %}
url: /services
method: POST
body:
  name: test-service
  host: httpbin.konghq.com
headers:
  - "Kong-Admin-Token:alex-token"
status_code: 201
{% endcontrol_plane_request %}

This time, the request succeeds with a `201` and creates a new Service.