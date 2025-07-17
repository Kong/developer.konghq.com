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

## User
A user is an individual who uses Insomnia to design, test, debug, and document APIs. As a user, you can design requests, mock services, run tests, and choose between local, Git, or cloud storage. As a user, you can work independently or collaborate in shared projects and tools.

## Admin
An admin is a team member or an organization owner in an Enterprise plan who controls organization-level access. As an admin, you configure SSO and SCIM, control storage settings, and enforce RBAC policies. Admins manage access and configuration at scale, however they cannot manage individual projects directly.

## Team
A team is a group of users who collaborate on shared Insomnia projects. As an admin, you can use teams to share API resources and apply RBAC rules to control collaborator permissions, and simplify access management across multiple users.

## Project
A project is a workspace that contains API collections, specifications, environments, and tests. You can store projects locally, sync with Insomnia Cloud, or connect them to Git repositories. Projects help you organize and share API workflows efficiently.

## Organization
An organization is a container for projects, teams, and access management. You can use organizations to centralize control across teams and assets by inviting collaborators, assigning RBAC roles, and configuring SSO.

## Owner
An owner is a user who holds full administrative control over an organization. As an owner, you can manage billing, invite members, configure settings, and assign additional owners. Ownership ensures consistent management and governance.

## Member
A member is an individual who collaborates on shared workspaces like projects or organizations based on their assigned roles. As a member, you can view or edit API assets depending on your RBAC permissions. You cannot manage the organization or access Enterprise-level settings.

## Co-owner
A co-owner is a user who shares full administrative control of an account, including billing, account settings, members, organizations, and projects. As a co-owner, you can perform all the same actions as the primary owner. Co-ownership ensures continuity by allowing multiple users to manage critical account functions.

## Billing-only
A billing-only user is a user who manages account billing information, however they don't have access to management for projects, members, and organizations. As a billing-only user, you cannot create organizations or modify API resources. This role is typically assigned to delegate payment responsibilities without granting administrative access.
