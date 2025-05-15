### Default {{site.base_gateway}} roles

By default, when {{site.base_gateway}} is configured, the starting user is configured as a **Super Admin** in the `default` Workspace. Workspaces, by default, contain the following roles: 

<!--vale off-->
{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
rows:
  - role: "`admin`"
    description: Full access to all endpoints, across all Workspaces, except the RBAC Admin API.
  - role: "`super-admin`"
    description: Full access to all endpoints, across all Workspaces, including the ability to assign and modify RBAC permissions.
  - role: "`read-only`"
    description: Read access to all endpoints, across all Workspaces.
{% endtable %}
<!--vale on-->

An admin has full permissions to every endpoint in {{site.base_gateway}}, but they can't assign and modify RBAC permissions.

{% mermaid %}

flowchart LR
    A((fa:fa-user Super-admin user<br><b>permissions<br>CRUD</b>))
    B(<b>Kong Manager</b>)
    C(<b>Admin API</b>)
    D(RBAC)
    E(Routes)
    F(Services)
    G(Plugins)
    H(Workspaces)
    A--> B & C
    subgraph id1 [Control Plane]
        B --> C
    direction LR
        subgraph id2 [Kong Entities]
        direction LR
        D
        E
        F
        G
        H
        end
    C --> D & E & F & G & H
    end

{% endmermaid %}
### Workspace roles

[Workspaces](/gateway/entities/workspace/) provide a way to logically segment configurations and entities with RBAC. Using RBAC, you can restrict access to groups of users and create roles within a Workspace so that users can manage each other. This is done using the [`workspaces/rbac/roles`](/api/gateway/admin-ee/#/operations/post-rbac-roles-workspace) endpoint.  

<!--vale off-->
{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
rows:
  - role: "`workspace-admin`"
    description: Full access to all endpoints in the Workspace, except the RBAC Admin API.
  - role: "`workspace-super-admin`"
    description: Full access to all endpoints in the Workspaces, including the ability to assign and modify RBAC.
  - role: "`workspace-portal-admin`"
    description: Full access to Dev Portal related endpoints in the Workspace.
  - role: "`workspace-read-only`"
    description: Read access to all endpoints in the Workspace.
{% endtable %}
<!--vale on-->

A role assigned in the `default` Workspace has permissions across all subsequently created Workspaces unless the roles in the specific Workplace are explicitly assigned. When a Workspace has explicitly assigned roles, they take precedent over the `default` Workspace. 

If RBAC roles and permissions are assigned from within a Workspace, they are specific to that Workspace. For example, if there are two Workspaces, Payments and Deliveries, an admin created in Payments doesn’t have access to any endpoints in Deliveries.
