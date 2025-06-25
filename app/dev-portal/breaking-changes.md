---
title: "Dev Portal breaking changes"
content_type: reference
layout: reference
breadcrumbs:
  - /dev-portal/
products:
    - gateway

works_on:
    - konnect

tags:
    - upgrades
    - versioning

description: "Review breaking changes from Dev Portal v2 to v3."

related_resources:
  - text: Dev Portal
    url: /dev-portal/
  - text: "{{site.konnect_short_name}} release notes"
    url: https://releases.konghq.com/en
---

With the GA release of the new Dev Portal (v3) in June 2025, some features and APIs have been updated or deprecated. See the following sections for a list of the changed features and how you can update your automation and workflows accordingly.

## Dev Portal default domain names

During Tech Preview and Beta, new Dev Portals were served on `https://{portalId}.edge.us.portal.konghq.tech`. The `https://{portalId}.edge.us.portal.konghq.tech` domain name will be discontinued on October 1, 2025 in favor of the `https://{portalId}.us.kongportals.com` domain. During the transition period from Dev Portal v3 release to October 2025, both domain names will be served, but Kong recommends updating your domain names to the new naming convention during the transition period. 

You must update Dev Portal domain names everywhere they are referenced, including the following:

* [OIDC or SAML](/dev-portal/sso/) callback URLs  
* [CORS plugin](/plugins/cors/) origin configuration  
* All links and bookmarks to your Dev Portal  
* [Custom domains](/dev-portal/custom-domains/) migration  
  In the next 1-2 weeks, we will provide emails to all Beta customers with guidance on migrating custom domains. 

## API specifications deprecated in favor of API versions

The [API specification endpoint](/api/konnect/api-builder/v3/#/operations/create-api-spec) is being deprecated on October 1, 2025 in favor of the [API versions endpoint](/api/konnect/api-builder/v3/#/operations/create-api-version). By moving to the `/apis/{id}/versions` endpoints, this allows you to support additional versions of a spec. Existing automation with specifications operations should work in parallel during this transition. Each existing specification will be 1:1 with a wrapping version entity.

The following `/apis/{id}/specifications` endpoints will be deprecated on October 1, 2025:  
* GET `/v3/apis/{id}/specifications` 
* GET `/v3/apis/{id}/specifications/{specId}`  
* PATCH `/v3/apis/{id}/specifications/{specId}`  
* DELETE `/v3/apis/{id}/specifications/{specId}`  
* POST `/v3/apis/{id}/specifications`  

They will be replaced with the following `/apis/{id}/versions` endpoints:
* GET `/v3/apis/{id}/versions`  
* GET `/v3/apis/{id}/versions/{versionId}`  
* PATCH `/v3/apis/{id}/versions/{versionId}`  
* DELETE `/v3/apis/{id}/versions/{versionId}`  
* POST `/v3/apis/{id}/versions`

## Auth strategy sync errors moving

Auth strategy sync errors will be moving from the API entity to the implementation entity.

The following endpoints are impacted:

* GET `/v3/apis`  
* GET `/v3/apis/{id}`

The `auth_strategy_sync_error` property will no longer be included on the API entity response. It will now be optionally included on the API implementation service property object. For example, if there's an error syncing the auth strategy configuration to the given implementation service when sending a GET request to the `/v3/apis/{id}/implementations` endpoint or a GET request to the `/v3/api-implementations` endpoint, the `response.body.service.auth_strategy_sync_error` will be present.

## Nested developers property removed from application responses

`response.body.developers` will no longer be included in the following endpoints:

* GET `/v3/portals/{portalId}/applications`  
* GET `/v3/portals/{portalId}/applications/{applicationId}`

Use the GET `/v3/portals/{portalId}/applications/{applicationId}/developers` endpoint instead.

## Implementations service property is now optional

You no longer need to specify the Gateway Service to associate with an implementation for the `/v3/apis/{id}/implementations` endpoints.

## Developer entity responses no longer include `application_count`

The following endpoints no longer include `application_count` in the response body:

* GET `/v3/portals/{portalId}/developers`  
* GET `/v3/portals/{portalId}/developers/{developerId}`

## Portal logo and favicon no longer use filename

Portal logo and favicon asset endpoints won't accept `filename` in the request bodies.

* PUT `/v3/portals/{portalId}/assets/logo`
* PUT `/portals/{portalId}/assets/favicon`

## Move page and API documentation is now POST, not PUT

* PUT `/v3/portals/{portalId}/pages/{pageId}/move` has changed to POST
* PUT `/v3/apis/{apiId}/documents/{documentId}/move` has changed to POST
