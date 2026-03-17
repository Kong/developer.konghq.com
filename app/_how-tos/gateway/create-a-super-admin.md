---
title: Create a Super Admin with the Admin API
permalink: /how-to/create-a-super-admin/
content_type: how_to
description: Learn how to create a Super Admin for {{site.base_gateway}}.
products:
    - gateway

rbac: true
works_on:
    - on-prem

tags:
  - authorization
  - access-control
  - rbac

tldr: 
  q: How do I create a {{site.base_gateway}} Super Admin using the Admin API?
  a: |
    After enabling [RBAC](/gateway/entities/rbac/#enable-rbac), you can create a Super Admin user by issuing a `POST` request to the [`/rbac/users/`](/api/gateway/admin-ee/#/operations/post-rbac-users) endpoint. Then associate the user to the `super-admin` role.

prereqs:
    inline:
      - title: Configure environment variables
        content: |
            Set the following variables: 
            * `KONG_ADMIN_TOKEN`: The `kong_password` variable set when configuring {{site.base_gateway}}
            * `ADMIN_NAME`: The name of the RBAC user that will be associated with the Super Admin Role.
            * `USER_TOKEN`: The authentication token to be presented to the Admin API.
            For example:
            {% env_variables %}
            KONG_ADMIN_TOKEN: kong
            ADMIN_NAME: tim
            USER_TOKEN: my-admin-token
            section: prereqs
            {% endenv_variables %}

        icon_url: /assets/icons/file.svg

min_version:
    gateway: '3.4'

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

related_resources:
  - text: Gateway RBAC
    url: /gateway/entities/rbac/
  - text: Gateway Groups
    url: /gateway/entities/group/
  - text: Gateway Admins
    url: /gateway/entities/admin/
  - text: Gateway Workspaces
    url: /gateway/entities/workspace/
  - text: Create an RBAC user with custom permissions
    url: /how-to/configure-rbac-user-in-kong-gateway/
---


## Create the super-admin RBAC user

1. Create an [RBAC](/gateway/entities/rbac/) user:
<!-- vale off -->
{% capture request %}
{% control_plane_request %}
url: /rbac/users
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Kong-Admin-Token: $KONG_ADMIN_TOKEN'
body:
    name: $ADMIN_NAME
    user_token: $USER_TOKEN
status_code: 201
{% endcontrol_plane_request %}
{% endcapture %}

{{request | indent: 3}}


1. Associate the user to the `super-admin` role:

{% capture request2 %}
{% control_plane_request %}
url: /rbac/users/$ADMIN_NAME/roles
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Kong-Admin-Token: $KONG_ADMIN_TOKEN'
body:
    roles: super-admin
status_code: 201
{% endcontrol_plane_request %}
{% endcapture %}

{{request2 | indent: 3}}

<!--vale on -->

## Validate

You can validate that the `super-admin` role was correctly assigned to the RBAC user using the [`/rbac/users/{user}/roles`](/api/gateway/admin-ee/#/operations/get-rbac-users-name_or_id-roles) endpoint: 

{% control_plane_request %}
url: /rbac/users/$ADMIN_NAME/roles
headers:
    - 'Kong-Admin-Token: $KONG_ADMIN_TOKEN'
status_code: 200
{% endcontrol_plane_request %}
If this was configured correctly the response body will look like this: 

```sh
{
	"user": {
		"enabled": true,
		"updated_at": 1737490456,
		"comment": null,
		"id": "49a1d4e5-e306-4b2d-a343-8973afd1360d",
		"created_at": 1737490456,
		"user_token_ident": "40a46",
		"name": "tim",
		"user_token": "$2b$09$578ORHJCMmpvDTVbB6hDkeIDsXZkUcgBQRemXdrwH2ex8IYBKWSE."
	},
	"roles": [
		{
			"created_at": 1737488148,
			"role_source": "local",
			"name": "super-admin",
			"updated_at": 1737488148,
			"ws_id": "fcde03f2-738e-4b29-a63e-fe0cdcc9a76e",
			"comment": "Full access to all endpoints, across all workspaces",
			"id": "3d7d7bfc-b894-4d9f-b28f-c9396bce201a"
		}
	]
}
```
{:.no-copy-code}

You can see that the RBAC role assigned to the user is `super-admin`.