# OpenAPI specs

* Konnect specs are managed through Platform API
* Gateway on-prem Admin API is generated through [kong-admin-spec-generator](https://github.com/Kong/kong-admin-spec-generator)

## Publishing a new spec

1. Check [workflow file](https://github.com/Kong/platform-api/blob/main/.github/raise-pr-on-change.json) in Platform API
to make sure the new spec is included in the "kong/developer.konghq.com" section. If not, add it the new spec to it.

1. The previous step will kick off an automatic update to the docs repo. Any public update to a spec opens a PR that looks like this: [feat(sdk): automated oas update](https://github.com/Kong/developer.konghq.com/pull/2372). 

   > Exception: If your feature isn't live but the spec is needed for an internal beta or tech preview, you need to grab the file manually.

1. Ask a PM to upload the spec to Konnect

1. Run the [Sync Konnect OAS data](https://github.com/Kong/developer.konghq.com/actions/workflows/sync-konnect-oas-data.yml) workflow and merge the generated PR.

### Uploading API spec to Konnect

If you need to upload a spec to Konnect:

1. Download the latest generated `public.yaml` file from the platform-api org, or copy the file from this repo at `app/api-specs/<platform>/<your-product>/<version>/openapi.yaml`.

1. Log into the Konnect Prod org through Okta ("The Konnect Org").

1. In the side menu, navigate to **API Products**.

1. Find your product and open it.

1. From the sidebar, open **Product Versions**, then open your version.

1. On the API Spec tab, open the **Edit** dropdown and click **Replace Spec**.

1. Replace and save. If the version is already published to the portal, this will automatically replace the published spec with your new file.


## Updating a spec

To update an existing spec, upload the newest version of the spec to the Konnect product organization. The update will happen automatically. 

If anything has changed in Konnect: 

Run the [Sync Konnect OAS data](https://github.com/Kong/developer.konghq.com/actions/workflows/sync-konnect-oas-data.yml) workflow and merge the generated PR.
