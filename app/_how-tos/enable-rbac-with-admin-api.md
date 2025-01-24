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
     To configure RBAC, create a [Super Admin user](/gateway/entities/rbac/#default-kong-gateway-roles) using the [`/rbac/users` endpoint](/api/gateway/admin-ee/3.9/#/operations/post-rbac-users), then enable RBAC on {{site.base_gateway}} by setting the `enable_rbac` setting to `on` in `kong.conf`.

min_version:
    gateway: '3.4'
prereqs:
    inline:
      - title: Configure environment variables
        content: |
            Set the `user_token`, which is the authentication token that's presented to the Admin API. For example: 
            ```sh
            export USER_TOKEN=my-admin-token
            ```
---


## 1. Create an RBAC Super Admin

In {{site.base_gateway}} A Super Admin has the ability to manage [Roles and permissions](/gateway/entities/rbac/#what-is-rbac) across Workspaces. Because the username `super-admin` matches the `super-admin` RBAC Role, the new user is automatically added to the `super-admin` Role. 

1. Create an [RBAC](/gateway/entities/rbac/) Super Admin by sending a `POST` request to the [`/rbac/users`](/api/gateway/admin-ee/3.9/#/operations/post-rbac-users) endpoint:
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
    

2. Validate the user was created correctly by sending a `GET` request to the [`/rbac/users/{name_or_id}/roles`](/api/gateway/admin-ee/3.9/#/operations/get-rbac-users-name_or_id-roles) endpoint:  

{% capture request %}
{% control_plane_request %}
  url: /rbac/users/super-admin/roles
{% endcontrol_plane_request %}
{% endcapture %}
{{request | indent: 3}}

The response body contains information about the `super-admin` user including a comment field that details what permissions the `super-admin` role contains and a hashed `user_token`. 

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

With a `super-admin` created, you can proceed to enable RBAC. The `super-admin` User is a requirement because after enabling RBAC you will be required to pass the `user_token` value as a header in all requests. Enabling RBAC requires restarting or reloading {{site.base_gateway}}, if you are using the deploy script, this is done from within the {{site.base_gateway}} Docker container. 

```sh
export KONG_ENFORCE_RBAC=on && kong reload
```

## 3. Validate 

After the Super Admin is created and RBAC is enabled, the `user_token` must be passed with Admin API requests otherwise the API will return a `401 Unauthorized` error.

You can validate that RBAC is enabled by attempting to create a user like you did in the first step without passing the `user_token`:

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