---
title: "Dev Portal breaking changes"
content_type: reference
layout: reference
breadcrumbs:
  - /dev-portal/
products:
    - dev-portal

works_on:
    - konnect

tags:
    - upgrades
    - versioning

description: "Review breaking changes from Dev Portal v3 beta to GA."

related_resources:
  - text: Dev Portal
    url: /dev-portal/
  - text: "{{site.konnect_short_name}} release notes"
    url: https://releases.konghq.com/en
---

With the GA release of the new Dev Portal (v3) in June 2025, some features and APIs have been updated or deprecated. See the following sections for a list of the changed features and how you can update your automation and workflows accordingly.

## Dev Portal default domain names

During Tech Preview and Beta, new Dev Portals were served on `https://{portalId}.edge.{geo}.portal.konghq.tech`. The `https://{portalId}.edge.{geo}.portal.konghq.tech` domain name will be discontinued on October 1, 2025 in favor of the `https://{portalId}.{geo}.kongportals.com` domain. During the transition period from Dev Portal v3 release to October 2025, both domain names will be served, but Kong recommends updating your domain names to the new naming convention during the transition period. 

You must update Dev Portal domain names everywhere they are referenced, including the following:

* [OIDC or SAML](/dev-portal/sso/) callback URLs . 
* [CORS plugin](/plugins/cors/) origin configuration.  
* All links and bookmarks to your Dev Portal.
* [Custom domain](#migrate-your-custom-domain) migration.  
  All beta customers will receive emails with guidance on migrating custom domains. 

## Migrate your custom domain

If you're using a [custom domain](/dev-portal/custom-domains/) that hasn't been migrated to the new DNS zone yet, you must follow additional migration steps. The new DNS zone is available concurrently with the old DNS zone until October 1, 2025. On October 1, 2025, the old DNS zone will be deactivated and custom domains that haven't been migrated will stop working.

### Dev Portal custom domain migration steps

1. **Lower your DNS TTL**  
   Before starting the migration, we recommend reducing the time-to-live (TTL) of your existing DNS records (for example, to 300 seconds). This ensures that DNS changes propagate quickly.

1. **Start the migration in your Dev Portal**  
   1. Navigate to [Dev Portal](https://cloud.konghq.com/portals/) in {{site.konnect_short_name}} and select the Dev Portal you want to migrate.
   1. In the sidebar, click **Settings** and the **Custom domains** tab.
   1. Locate your custom domain in the table and click on the menu icon **⋮** next to it.
   1. Select **Migrate**.

3. **Update your DNS records**  
   You'll be provided with a new **CNAME target** (for example, `081754c63259.us.kongportals.tech`).  
   Update your DNS provider's configuration to point your custom domain to this new target.

## Breaking changes

Review the following Dev Portal breaking changes and make any necessary updates to your configuration.

### API specifications deprecated in favor of API versions

The [API specification endpoint](/api/konnect/api-catalog/v3/#/operations/create-api-spec) is being deprecated on October 1, 2025 in favor of the [API versions endpoint](/api/konnect/api-catalog/v3/#/operations/create-api-version). 
Moving to the `/apis/{id}/versions` endpoints allows you to support additional versions of a spec. 
Existing automation with specifications operations should work in parallel during this transition. 
Each existing specification will be mapped one-to-one with a wrapping version entity.

The following `/apis/{id}/specifications` endpoints will be deprecated on October 1, 2025 and replaced with `/apis/{id}/versions` endpoints:

{% table %}
columns:
  - title: Old endpoint
    key: old
  - title: New endpoint
    key: new
rows:
  - old: "`GET /v3/apis/{id}/specifications`"
    new: "`GET /v3/apis/{id}/versions`"
  - old: "`GET /v3/apis/{id}/specifications/{specId}`"
    new: "`GET /v3/apis/{id}/versions/{versionId}`"
  - old: "`PATCH /v3/apis/{id}/specifications/{specId}`" 
    new: "`PATCH /v3/apis/{id}/versions/{versionId}`"
  - old: "`DELETE /v3/apis/{id}/specifications/{specId}`" 
    new: "`DELETE /v3/apis/{id}/versions/{versionId}`"
  - old: "`POST /v3/apis/{id}/specifications`"
    new: "`POST /v3/apis/{id}/versions`"
{% endtable %}

### Auth strategy sync errors moving

Auth strategy sync errors will be moving from the API entity to the implementation entity.

The following endpoints are impacted:

* `GET /v3/apis`  
* `GET /v3/apis/{id}`

The `auth_strategy_sync_error` property will no longer be included on the API entity response. It will now be optionally included on the API implementation service property object. For example, if there's an error syncing the auth strategy configuration to the given implementation service when sending a GET request to the `/v3/apis/{id}/implementations` endpoint or a GET request to the `/v3/api-implementations` endpoint, the `response.body.service.auth_strategy_sync_error` will be present.

### Nested developers property removed from application responses

`response.body.developers` will no longer be included in the following endpoints:

* `GET /v3/portals/{portalId}/applications`  
* `GET /v3/portals/{portalId}/applications/{applicationId}`

Use the GET `/v3/portals/{portalId}/applications/{applicationId}/developers` endpoint instead.

### Implementations service property is now optional

You no longer need to specify the Gateway Service to associate with an implementation for the `/v3/apis/{id}/implementations` endpoints.

### Developer entity responses no longer include `application_count`

The following endpoints no longer include `application_count` in the response body:

* GET `/v3/portals/{portalId}/developers`  
* GET `/v3/portals/{portalId}/developers/{developerId}`

### API documentation `labels` property removed

API documentation entities will no longer support `labels`:

* `GET /v3/apis/{apiId}/documents`
* `GET /v3/apis/{apiId}/documents/{documentId}`
* `PATCH /v3/apis/{apiId}/documents/{documentId}`

Use the API entity instead.

### Portal logo and favicon no longer use filename

Portal logo and favicon asset endpoints won't accept `filename` in the request bodies:

* `PUT /v3/portals/{portalId}/assets/logo`
* `PUT /v3/portals/{portalId}/assets/favicon`

### Move page and API documentation endpoints are now POST, not PUT

The following endpoint HTTP methods have been updated:

* `PUT /v3/portals/{portalId}/pages/{pageId}/move` has changed to POST
* `PUT /v3/apis/{apiId}/documents/{documentId}/move` has changed to POST
