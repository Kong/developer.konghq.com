---
title: Insomnia terminology reference

description: This page defines concepts related to Insomnia.
breadcrumbs: 
  - /insomnia/
search_aliases:
  - Insomnia terms
content_type: reference
layout: reference

products:
- insomnia

---

## Design document
A design document is a workspace containing tools to design an API specification. You can write and edit a spec, generate a collection from the spec to send requests, and create test suites to run different types of tests against your API or API spec.

For more details, see [Documents](/insomnia/documents/)

## Request collection
A request collection is a workspace for sending requests. You can create new requests or import requests from an API spec, clipboard, or even from a Postman collection. Requests can be customized with environment variables, template tags, pre-request and after-response scripts. Requests can be run individually or as a series of requests to run together.

For more details, see [Collections](/insomnia/collections/)

## Mock server
A mock server is a self-hosted or cloud-hosted way to simulate an API endpoint. You can create a mock server and define endpoints manually, or generate them from existing responses. You can customize the response code, body, and headers.

For more details, see [Mock servers](/insomnia/mock-servers/).

## Scratch Pad
The Insomnia Scratch Pad is a local workspace that you can use to send requests. It doesn't require creating an Insomnia account. The Scratch Pad functions as a collection, and you have access to all collection features.

For more details, see [Scratch Pad](/insomnia/storage/#scratch-pad).

## Collection Runner
The Collection Runner is a tool that allows you to send multiple requests in a specific order. You can also chain requests to reuse elements from a request or response in another one.

For more details, see [Use the Collection Runner](/how-to/use-the-collection-runner/) and [Chain requests](/how-to/chain-requests/).

## Template tag
A template tag is a type of variable that you can use to reference or transform values. You can reuse an element from a request or a response, get the current timestamp, encode a value, prompt the user for an input value, etc.

## Pre-request script
A pre-request script is a feature in a collection that allows you to define actions to perform before running a request. For example, you can set a variable, add a query parameter, remove a header, etc. Once you send the request, the pre-request script runs before the request is actually sent. The results of the script are displayed in the console.

## After-response script
An after-response script is a feature in a collection that allows you to define actions to perform after receiving the response to a request. For example, you can get the response body, check for data types, clear a variable, etc. The results of the script are displayed in the console.

{% table %}
columns:
  - title: Role
    key: role
  - title: Description
    key: description
rows:
  - role: User
    description: An individual who uses Insomnia to design, test, debug, and document APIs. Users can design requests, mock services, run tests, and choose between local, Git, or cloud storage. They can work independently or collaborate in shared projects and tools.
  - role: Admin
    description: A team member or organization owner on an Enterprise plan who controls organization-level access. Admins configure SSO and SCIM, control storage settings, and enforce RBAC policies. They manage access and configuration at scale but cannot manage individual projects directly.
  - role: Team
    description: A Group of users who collaborate on shared Insomnia projects. Admins use teams to share API resources, apply RBAC rules to control permissions, and simplify access management.
  - role: Project
    description: A Workspace that contains API collections, specifications, environments, and tests. Projects can be stored locally, synced with Insomnia Cloud, or connected to Git repositories. They help organize and share API workflows.
  - role: Organization
    description: A container for projects, teams, and access management. Organizations centralize control by allowing collaborators to be invited, RBAC roles to be assigned, and SSO to be configured.
  - role: Owner
    description: A user with full administrative control over an organization. Owners manage billing, invite members, configure settings, and assign additional owners to ensure consistent management and governance.
  - role: Member
    description: An individual who collaborates on shared workspaces based on assigned roles. Members can view or edit API assets according to RBAC permissions but cannot manage the organization or access Enterprise-level settings.
  - role: Co-owner
    description: A user who shares full administrative control of an account. Co-owners can manage billing, settings, members, organizations, and projects, ensuring continuity in account management.
  - role: Billing-only
    description: A user who manages billing information but does not have access to manage projects, members, or organizations. Typically used to delegate payment responsibilities without granting administrative access.
{% endtable %}
