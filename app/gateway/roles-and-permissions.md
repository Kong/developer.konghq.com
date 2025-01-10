---
title: RBAC Roles and Permissions
description: With RBAC can you create roles and permissions and assign them to users. These rules can vary across workspaces.
content_type: reference
layout: reference
products:
   - gateway
related_resources:
  - text: Route entity
    url: /gateway/entities/route/
  - text: Workspace
    url: /gateway/entities/workspace/
  - text: RBAC
    url: /gateway/entities/rbac/

   
---

Roles and permissions are administered using the {{site.base_gateway}} [RBAC system](/gateway/entities/rbac/). Roles are sets of permissions that can be assigned to admins and users and can be specific to a [Workspace](/gateway/entities/workspace). {{site.base_gateway}} uses a precedence model, from most specificity to least specificity, to determine if a user has access to an endpoint.


## Default {{site.base_gateway}}  roles

By default, when {{site.base_gateway}} is configured, the starting user is configured as a **Super Admin** in the `default` Workspace. Workspace's by default contain the following roles: 

| Role      | Description |
| ----------- | ----------- |
| Admin | Full access to all endpoints, across all Workspaces, except the RBAC Admin API  |
| `super-admin`   | Full access to all endpoints, across all Workspaces, ability to assign and modify RBAC permissions.     |
|`read-only`| Read access to all endpoints, across all Workspaces|

An **Admin** has full permissions to every endpoint in {{site.base_gateway}}, but they can't assign and modify RBAC permissions. An **Admin** can't modify their own permissions, or configure the permissions of the **Super Admin**.   

## Workspace roles

| Role      | Description |
| ----------- | ----------- |
|`workspace-admin` | Full access to all endpoints in the Workspace, except the RBAC Admin API.| 
|`Workspace-read-only` | Read access to all endpoints in the Workspace | 

A role assigned in the `default` WorkSpace has permissions across all subsequently created Workspaces unless the roles in the specific Workplace are explicitly assigned. When a Workspace has explicitly assigned roles, they take precedent over the `default` Workspace. 


## Role configuration

This diagram helps explain how individual workspace roles and cross-workspace roles interact. 

{% mermaid %}
flowchart LR
    subgraph team-a-roles [Team A Roles]
        Admin2["Admin"]
        RO2["Read Only"]
        C2["Custom"]
    end 
    subgraph team-b-roles [Team B Roles]
        Admin3["Admin"]
        RO3["Read Only"]
        C3["Custom"]
    end 
    subgraph cross-workspace-roles [Platform Admins]
        SA["Super Admin"]
        Admin["Admin"]
        RO["Read Only"]
        C["Custom"]
    end 

    subgraph defaultWorkspace [Default Workspace]
        routes["Route"]
        service["Service"]
        plugin["Plugin"]
    end

    subgraph teamAworkspace [Team A Workspace]
        routes2["Route"]
        service2["Service"]
        plugin2["Plugin"]
    end
    subgraph teamBworkspace [Team B Workspace]
       routes3["Route"]
        service3["Service"]
        plugin3["Plugin"]
    end

    team-a-roles --> teamAworkspace
    team-b-roles --> teamBworkspace
    cross-workspace-roles --> defaultWorkspace
    cross-workspace-roles --> teamAworkspace
    cross-workspace-roles --> teamBworkspace


{% endmermaid %}