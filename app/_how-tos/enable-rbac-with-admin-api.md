---
title: Enable RBAC with the Admin API
content_type: how_to

products:
    - gateway
tier: enterprise
works_on:
    - on-prem

related_resources:
  - text: Gateway RBAC entity
    url: /gateway/entities/rbac/
  - text: Gateway Group entity
    url: /gateway/entities/group/
  - text: Gateway Admin entity
    url: /gateway/entities/admin/
  - text: Workspaces entity
    url: /gateway/entities/workspace


tldr: 
  q: How do I configure RBAC?
  a: |
     To configure RBAC, create a Super Admin user, then enable RBAC on {{site.base_gateway}} by setting the `enable_rbac` setting to `on`.

min_version:
    gateway: '3.4'
prereqs:
    inline:
      - title: Configure environment variables
        content: |
            Set the `user_token`: 
            * `USER_TOKEN`: The authentication token to be presented to the Admin API.
            For example: 
            ```sh
            export USER_TOKEN=my-admin-token
            ```
---


## 1. Create an RBAC Super Admin

In {{site.base_gateway}} A Super Admin has the ability to manage Roles and permissions across Workspaces. Because the username `super-admin` matches the `super-admin` RBAC Role, the new user is automatically added to the `super-admin` Role. 

1. Create an [RBAC](/gateway/entities/rbac/) Super Admin
<!-- vale off -->
{% capture request %}
{% control_plane_request %}
  url: /rbac/users
  method: POST
  body:
      name: super-admin
      user_token: $USER_TOKEN
  headers:
      - 'Accept: application/json'
      - 'Content-Type: application/json'
{% endcontrol_plane_request %}
{% endcapture %}

{{request | indent: 3}}
<!-- vale on -->
    

2. Validate the user was created correctly:  

{% capture request %}
{% control_plane_request %}
  url: /rbac/users/super-admin/roles
{% endcontrol_plane_request %}
{% endcapture %}
{{request | indent: 3}}

The response body contains information about the `super-admin` user including, a comment field which expresses what permissions the `super-admin` role contains, and hashed a `user_token`. 

```json
    {
    "user": {
        "created_at": 1737580506,
        "enabled": true,
        "updated_at": 1737580506,
        "id": "7d4be888-72f4-4301-b6f7-18d157976f53",
        "user_token_ident": "bd4fa",
        "name": "super-admin",
        "user_token": "$2b$09$SbBJHLkmYuUC2XtfmsYMKeJB/IkfBQeZDamEKGMMAbDtHcg8QlyQC",
        "comment": null
    },
    "roles": [
        {
        "role_source": "local",
        "updated_at": 1737580488,
        "comment": "Full access to all endpoints, across all workspaces",
        "created_at": 1737580488,
        "id": "d49ccbd7-79a9-4687-abb2-4647e4114d92",
        "name": "super-admin",
        "ws_id": "9fb43832-6ce2-425d-9a33-5450b24b2c00"
        }
    ]
    }
```

## 2. Enable RBAC

With a `super-admin` created, you can proceed to enable RBAC. This requires restarting or reloading {{site.base_gateway}}.

```sh
export KONG_ENFORCE_RBAC=on && kong restart
```

## 3. Validate 

After the Super Admin is created, the `user_token` has to be passed with Admin API requests otherwise the API will return a `401 Unauthorized` error.

You can validate that RBAC is enabled by attempting to create a user like you did in the first step without passing the `user_token`. 

<!-- vale off -->

{% control_plane_request %}
  url: /rbac/users/
{% endcontrol_plane_request %}

<!-- vale on -->

If RBAC was enabled correctly this request will return: 
```
{
	"message": "Invalid RBAC credentials"
}
```

Passing the same request with the `user-token` will return a `200` and the list of {{site.base_gateway}} users.
{% control_plane_request %}
  url: /rbac/users
  headers:
    - "Kong-Admin-Token: $USER_TOKEN"
{% endcontrol_plane_request %}