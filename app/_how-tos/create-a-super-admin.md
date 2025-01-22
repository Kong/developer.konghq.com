---
title: Create a Super Admin with the Admin API
content_type: how_to

products:
    - gateway
tier: enterprise
rbac: true
works_on:
    - on-prem

tldr: 
  q: How do I create a {{site.base_gateway}} Super Admin using the Admin API
  a: |
    After enabling [RBAC](/gateway/entities/rbac/#enable-rbac), you can create a Super-Admin user by issuing a `POST` request to the [`/rbac/users/`](/api/gateway/admin-ee/#/operations/post-rbac-users) endpoint. Then associate the user to the `super-admin` role.

prereqs:
    inline:
      - title: Configure environment variables
        content: |
            Set the `kong-admin-token`, `name`, and `user_token`: 
            * `KONG_ADMIN_TOKEN`: The `kong_password` variable set when configuring {{site.base_gateway}}
            * `ADMIN_NAME`: The name of the RBAC user that will be associated with the Super Admin Role.
            * `USER_TOKEN`: The authentication token to be presented to the Admin API.
            For example: 
            ```sh
            export KONG_ADMIN_TOKEN=kong
            export ADMIN_NAME=tim
            export USER_TOKEN=my-admin-token
            ```
        icon_url: /assets/icons/file.svg

min_version:
    gateway: '3.4'
---


## Create the RBAC user and assign it the `super-admin` role: 

1. Create an [RBAC](/gateway/entities/rbac/) user

		{% control_plane_request %}
			url: /rbac/users
			status_code: 201
			method: POST
			headers:
					- 'Accept: application/json'
					- 'Content-Type: application/json'
					- 'Kong-Admin-Token: $KONG_ADMIN_TOKEN'
			body:
					name: $ADMIN_NAME
					user_token: $USER_TOKEN
		{% endcontrol_plane_request %}

1. Associate the user to the `super-admin` role.
					
	{% control_plane_request %}
	url: /rbac/users/$ADMIN_NAME/roles
	status_code: 201
	method: POST
	headers:
			- 'Accept: application/json'
			- 'Content-Type: application/json'
			- 'Kong-Admin-Token: $KONG_ADMIN_TOKEN'
	body:
			roles: "super-admin"
	{% endcontrol_plane_request %}

## Validate

You can validate that the RBAC user was correctly assigned to the `super-admin` Role using the [`/rbac/users/{user}/roles`](/api/gateway/admin-ee/#/operations/get-rbac-users-name_or_id-roles) endpoint: 

{% control_plane_request %}
url: /rbac/users/$ADMIN_NAME/roles
headers:
  - 'Kong-Admin-Token:$KONG_ADMIN_TOKEN'
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
You can see that the RBAC role assigned to the User is `super-admin`.