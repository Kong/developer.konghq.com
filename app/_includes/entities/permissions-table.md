## Default {{site.base_gateway}}  roles

By default, when {{site.base_gateway}} is configured, the starting user is configured as a **Super Admin** in the `default` Workspace. Workspace's by default contain the following roles: 

| Role      | Description |
| ----------- | ----------- |
| Admin | Full access to all endpoints, across all Workspaces, except the RBAC Admin API  |
| `super-admin`   | Full access to all endpoints, across all Workspaces, ability to assign and modify RBAC permissions.     |
|`read-only`| Read access to all endpoints, across all Workspaces|

An **Admin** has full permissions to every endpoint in {{site.base_gateway}}, but they can't assign and modify RBAC permissions. An **Admin** can't modify their own permissions, or configure the permissions of the **Super Admin**.   

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
## Workspace roles

[Workspaces](/gateway/entities/workspace/) provide a way to logically segment configurations and entities with RBAC. Using RBAC you can restrict access to groups of users and create roles within a Workspace so that users can manage each other. This is done using the [`workspaces/rbac/roles`](/api/gateway/admin-ee/3.9/#/operations/post-rbac-roles-workspace) endpoint.  

| Role      | Description |
| ----------- | ----------- |
|`workspace-admin` | Full access to all endpoints in the Workspace, except the RBAC Admin API.| 
|`Workspace-read-only` | Read access to all endpoints in the Workspace | 

A role assigned in the `default` WorkSpace has permissions across all subsequently created Workspaces unless the roles in the specific Workplace are explicitly assigned. When a Workspace has explicitly assigned roles, they take precedent over the `default` Workspace. 
