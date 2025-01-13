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


{% include entities/permissions-table.md %}


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