---
title: Insomnia terminology

description: This page defines terminology and concepts related to Insomnia.

breadcrumbs: 
  - /insomnia/

search_aliases:
  - Insomnia terms

content_type: reference

layout: reference

products:
- insomnia

tags:
- glossary
---
## User
A user is any individual who uses Insomnia, either as a scratch pad user that works locally without signing in, or as a signed-in user with cloud/Git sync. Users design, test, debug, and document APIs by creating requests, mocking services, and running tests. They can choose where to store data; locally, in Git, or in the cloud. They can work independently or collaborate in shared projects and tools. 

### Collaborator
A collaborator is a user who is invited to join and work in shared organizations in Insomnia. Collaborators participate in workflows by viewing or editing API assets, and contributing to tests and mocks based on their organization level roles. Pro and Enterprise plans let you invite unlimited collaborators and manage their access through role based access control (RBAC), which enables secure and scalable team collaboration.

### User roles
User roles are permissions assigned at the account or organization level that define what individuals can do in Insomnia. These roles include account wide abilities such as managing billing or performing account administration and organization specific permissions such as editing API assets or managing invites.

To understand the different terms used in Insomnia that are related to roles, use the following table:

{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
rows:
  - role: Admin
    description: An admin is a team member who manages organization-level settings. Admins manage organization membership and settings like storage limits and invite policies. This role is assigned at the organization level.
  - role: Owner
    description: An owner is a user with full administrative control over an organization. Owners can delete the organization, manage membership, configure organization settings like storage limits and invite policies, and assign additional owners to ensure consistent management and governance. This role is assigned at the organization level.
  - role: Member
    description: An individual who collaborates on shared workspaces based on assigned roles. Members can view or edit API assets according to RBAC permissions but cannot manage the organization or access Enterprise-level settings. This role is assigned at the organization level.
  - role: Co-owner
    description: "A user who shares full administrative control of an account. Co-owners can manage billing, settings, members, organizations, and projects, ensuring continuity in account management. This role is assigned at the user account level. For more details, see [Add co-owners](/insomnia/enterprise-account-management/#add-co-owners)."
  - role: Billing-only
    description: A user who manages billing information but does not have access to manage projects, members, or organizations. Typically used to delegate payment responsibilities without granting administrative access. This role is assigned at the user account level.
{% endtable %}

## Collaboration and workspace management

To understand the different terms used in Insomnia that are related to collaboration or workspace management, use the following table:

{% table %}
columns:
  - title: Feature
    key: feature
  - title: Description
    key: description
rows:
  - feature: Team
    description: "A team is a group of users who collaborate on shared Insomnia projects. Admins use teams to share API resources, apply RBAC rules to control permissions, and simplify access management. For more details, see [Insomnia teams](/insomnia/enterprise-user-management/#insomnia-teams)."
  - feature: Project
    description: A project is a workspace that contains API collections, specifications, environments, and tests. Projects can be stored locally, synced with Insomnia Cloud, or connected to Git repositories. They help organize and share API workflows.
  - feature: Organization
    description: "An organization is a container for projects, teams, and access management. Organizations centralize control by allowing collaborators to be invited, RBAC roles to be assigned, and SSO to be configured. For more details, see [Organizations](/insomnia/organizations/)."
  - feature: Domain
    description: "A domain is a verified email domain added to an Insomnia Enterprise account. A domain acts as the foundation for domain-based user access rules. For example: domain capture, domain lock, and invite‑control. You can automatically manage onboarding, license assignment, and organizational access based on user email addresses in that domain. For more information, go to [Enterprise account management](/insomnia/enterprise-user-management/)." 
{% endtable %}

## Workspaces and API design tools

To understand the different terms used in Insomnia that are related to workspaces and API design tools, use the following table:

{% table %}
columns:
  - title: Tool
    key: tool
  - title: Description
    key: description
rows:
  - tool: Design Document
    description: "A design document is a workspace that contains tools to design an API specification. You can write and edit a spec, generate a collection from the spec to send requests, and create test suites to run different types of tests against your API or API spec. For more details, see [Documents](/insomnia/documents/)."
  - tool: Request collection
    description: "A request collection is a workspace for sending requests. You can create new requests or import requests from an API spec, clipboard, or even from a Postman collection. Requests can be customized with environment variables, template tags, pre-request and after-response scripts. Requests can be run individually or as a series of requests to run together. For more details, see [Collections](/insomnia/collections/)."
  - tool: Mock server
    description: "A mock server is a self-hosted or cloud-hosted way to simulate an API endpoint. You can create a mock server and define endpoints manually, or generate them from existing responses. You can customize the response code, body, and headers. For more details, see [Mock servers](/insomnia/mock-servers/)."
  - tool: Scratch pad
    description: "The Insomnia Scratch Pad is a local workspace that you can use to send requests. It doesn't require creating an Insomnia account. The Scratch Pad functions as a collection, and you have access to all collection features. For more details, see [Scratch Pad](/insomnia/storage/#scratch-pad)."
  - tool: Collection runner
    description: "The Collection Runner is a tool that allows you to send multiple requests in a specific order. You can also chain requests to reuse elements from a request or response in another one. For more details, see [Use the Collection Runner](/how-to/use-the-collection-runner/) and [Chain requests](/how-to/chain-requests/)."
{% endtable %}

## Scripting and automation

To understand the different terms used in Insomnia that are related to scripting or automation, use the following table:

{% table %}
columns:
  - title: Capabilities
    key: capabilities
  - title: Description
    key: description
rows:
  - capabilities: Template tag
    description: "A template tag is a type of variable that you can use to reference or transform values. You can reuse an element from a request or a response, get the current timestamp, encode a value, and prompt the user for an input value. For more details, see [Template tags](/insomnia/template-tags/)."
  - capabilities: Pre-request script
    description: "A pre-request script is a feature in a collection that allows you to define actions to perform before running a request. For example, you can set a variable, add a query parameter, and remove a header. Once you send the request, the pre-request script runs before the request is actually sent. The results of the script are displayed in the console. For more details, see [Pre-request scripts](/insomnia/scripts/#pre-request-scripts)."
  - capabilities: After-response script
    description: "An after-response script is a feature in a collection that allows you to define actions to perform after receiving the response to a request. For example, you can get the response body, check for data types, and clear a variable. The results of the script are displayed in the console. For more details, see [After-response scripts](/insomnia/scripts/#after-response-scripts)."
{% endtable %}
