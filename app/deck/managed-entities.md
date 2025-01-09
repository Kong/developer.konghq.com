---
title: Entities Managed by decK

description: "decK manages entity configuration for{{site.base_gateway}}, including all core proxy entities."

content_type: reference
layout: reference

works_on:
    - on-prem
    - konnect

products:
  - api-ops

tools:
  - deck

related_resources:
  - text: Customize decK object defaults
    url:  /how-to/custom-deck-object-defaults

breadcrumbs:
  - /deck/
---


decK manages entity configuration for {{site.base_gateway}}, including all core proxy entities.

It does not manage {{site.base_gateway}} configuration parameters in `kong.conf`, or content and configuration for the Dev Portal.


| Entity | Managed by decK? |
| -------|-----------------| 
| Services | ✓ |
|Routes | ✓ |
|Consumers | ✓ |
|Plugins | ✓ |
|Certificates |✓ |
|CA Certificates | ✓ |
|SNIs | ✓ |
|Upstreams | ✓ |
|Targets | ✓ |
|Vaults | ✓ |
|Keys and key sets | × |
|Licenses | × |
|Workspaces | ✓ |
|RBAC: roles and endpoint permissions | ✓ |
|RBAC: groups and admins | × |
|Developers | × |
|Consumer groups | × |
|Event hooks | × |
|Keyring and data encryption | × |


{:.info}
> decK doesn't manage documents (`document_objects`) related to services, which means they are not included in dump/sync actions.
If you attempt to delete a service that has an associated document via decK, it will fail.
[Manage service documents directly](/gateway/latest/kong-enterprise/dev-portal/applications/managing-applications/#add-a-document-to-your-service) through Kong Manager. 
<br><br>
> decK can create workspaces and manage entities in a given workspace. 
However, decK can't delete workspaces, and it can't update multiple workspaces simultaneously.
See [Manage multiple workspaces](/deck/{{page.release}}/guides/kong-enterprise/#manage-multiple-workspaces) for more information.