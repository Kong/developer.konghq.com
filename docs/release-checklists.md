# Release checklists
* [Konnect apps and platform](#konnect-release-checklist)
* [Kong Gateway](#gateway-release-checklist)

## Konnect release checklist
1. [Publish OpenAPI specs](#openapi-specs)
1. Provide netlify preview link to PM

After merging release branch, and once the Netlify build is complete and docs are visible on developer.konghq.com:
1. [Run Algolia crawler](#algolia)
1. [Update sources in Kapa](#kapa)

## Gateway release checklist

### Minor or major releases

For minor or major version releases (e.g. 3.10 or 4.0):

1. [Generate references: kong.conf, CLI, PDK, plugin schemas](#generate-docs)
1. [Update Admin API](#updating-the-gateway-admin-api-spec)
1. [Add GPG and RSA keys](#add-gpg-and-rsa-keys)
1. [Generate changelogs and update breaking changes](#generate-changelogs)
1. [Update support matrix](#support-matrix)
1. [Bump the release version, tag as latest, and set release date](#bump-release-version)
1. [Update SBOM link](#sbom-link)
1. Search for and remove all `if_version` tags for the release that you're publishing
1. Add latest Postgres version to support matrix after engineering release tests pass

After merging release branch, and once the Netlify build is complete and docs are visible on developer.konghq.com:
1. [Run Algolia crawler](#algolia)
1. [Update sources in Kapa](#kapa)

After Gateway is available on Konnect:
1. [Update Konnect supported versions][#konnect-support]

There are a few items that we expect to come from engineering teams with each release:
* [Performance benchmark update](https://developer.konghq.com/gateway/performance/benchmarks/)
* [Konnect compatibility errors reference](https://developer.konghq.com/gateway-manager/version-compatibility/)

### Patch releases 

For patch releases (e.g. 3.10.0.2):

1. [Generate changelogs](#generate-changelogs)
2. [Bump the release version and set release date](#bump-release-version)

After merging release branch, and once the netlify build is complete and docs are visible on developer.konghq.com:
1. [Run Algolia crawler](#algolia)
1. [Update sources in Kapa](#kapa)

## Release tasks

### Generate changelogs

1. Pull down the version branch of kong-ee that you're generating the changelog for (e.g, `next/3.10.x.x`).
2. In your local clone of the docs repo, add any known issues for your version under `tools/changelog-generator/missing_entries/<version-number>`.
3. Go to the changelog folder and generate the changelog:

   ```sh
   cd tools/changelog-generator
   node run.js --path='../../../kong-ee' --version='3.10.0.2'
   ```

4. Go to the plugins changelog generator folder and generate the plugin changelogs:

   ```sh
   cd ../plugins-changelog-generator
   node run.js --version='3.10.0.2'
   ```

5. Generate the entire changelog from the sources:

   ```sh
   node changelog.js 
   ```

For more info:

* [Changelog README](../tools/changelog-generator/README.md)
* [Plugins changelog README](../tools/plugins-changelog-generator/README.md)

#### Breaking changes

Some of the items in the changelog will be categorized as "breaking changes". If there are any breaking changes entries generated, add them to https://developer.konghq.com/gateway/breaking-changes/ with some extra detail + links if possible.

Known issues with detailed workarounds also go here.

### Support matrix

Each release version in the `app/_data/products/gateway.yml` file has a matrix of supported OSes and tools.
If there are any changes, additions, deprecations of OS or tool support in the changelog, update this matrix accordingly.

For example, here's a changelog entry that would require updating the matrix:

```
Debian 10, CentOS 7, and RHEL 7 reached their End of Life (EOL) dates on June 30, 2024. As of version 3.8.0.0 onward, Kong is not building installation packages or Docker images for these operating systems. Kong is no longer providing official support for any Kong version running on these systems.
```

In this case, we would remove Debian 10, CentOS 7, and RHEL 7 from the supported versions for 3.8.0.0.

### Bump release version

Bump the release version and set a release date in `app/_data/products/gateway.yml`.

1. Under `releases`, update:
  * Replace `label: unreleased` with `latest: true` for the new version, and remove `latest: true` from the previous version.
  * `release` - update if adding a new major or minor release.
  * `ee-version` - update for any major, minor, or patch release.
  * `eol` - update if adding a major or minor release. 
     
    Add exactly one year to the release date to find the EOL (e.g., if release date 2025-07-03, EOL is 2026-07-03).
    
    > Exception: If the version is an LTS, add three years.

2. Under `release_dates`, add a new entry and set the date in `year/month/day` format.

### Add GPG and RSA keys

1. Go to `https://cloudsmith.io/~kong/repos/gateway-<version>/pub-keys/`. 
   
   For example, https://cloudsmith.io/~kong/repos/gateway-311/pub-keys/.

2. Add the short public GPG key and public RSA key to `app/_data/products/gateway.yml` in the `public_keys` section.

### SBOM link

1. Get updated link from engineering.
1. Add a new entry to https://developer.konghq.com/gateway/sbom/.

### Generate docs

#### kong.conf reference

Follow instructions in [`tools/kong-conf-to-json/README.md`](../tools/kong-conf-to-json/README.md) to generate the reference for your version.

#### PDK references

TBA.

#### CLI reference

TBA.

#### Plugin schemas

In the kong/docs-plugin-toolkit repo, you'll need to run a few workflows. 

1. [Download schemas](https://github.com/Kong/docs-plugin-toolkit/actions/workflows/download-schemas.yml)
    Use the branch generated in this first step to run all the subsequent steps, in order.
1. [Generate plugin priorities](https://github.com/Kong/docs-plugin-toolkit/actions/workflows/generate-plugin-priorities.yml)
1. [Generate referenceable fields](https://github.com/Kong/docs-plugin-toolkit/actions/workflows/generate-referenceable-fields.yml)
1. [Generate JSON schemas](https://github.com/Kong/docs-plugin-toolkit/actions/workflows/generate-json-schemas.yml)

### OpenAPI specs

* Konnect specs are managed through Platform API
* Gateway on-prem Admin API is generated through [kong-admin-spec-generator](https://github.com/Kong/kong-admin-spec-generator)

#### Publishing a new spec

1. Check [workflow file](https://github.com/Kong/platform-api/blob/main/.github/raise-pr-on-change.json) in Platform API
to make sure the new spec is included. If not, add it the new spec to it.

1. The previous step will kick off an automatic update to the docs repo. Any public update to a spec opens a PR that looks like this: [feat(sdk): automated oas update](https://github.com/Kong/developer.konghq.com/pull/2372). 

   > Exception: If your feature isn't live but the spec is needed for an internal beta or tech preview, you need to grab the file manually.

1. Ask a PM to upload the spec to Konnect

1. Run the [Sync Konnect OAS data](https://github.com/Kong/developer.konghq.com/actions/workflows/sync-konnect-oas-data.yml) workflow and merge the generated PR.

1. Make sure the spec is added to [Kapa](#kapa).

#### Updating an existing Konnect spec

1. Merge the generated ["feat(sdk): automated oas update"](https://github.com/Kong/developer.konghq.com/pull/2372) (example) PR. 

1. For any new features, ask the PM to upload the spec to Konnect.
  
   If the change is doc-driven, then update the spec in Konnect yourself.

#### Updating the Gateway Admin API spec

1. Clone the https://github.com/Kong/kong-admin-spec-generator repo locally.
1. Run `DOCKER_IMAGE=kong/kong-gateway:3.11.0.0 make setup-kong` (adjust for your own version).

    If generating from an RC, pass the RC registry name and tag: `DOCKER_IMAGE=kong/kong-gateway-dev:3.11.0.0-rc.5 make setup-kong`

1. Run `make kong`.
1. Copy the generated spec file into `developer.konghq.com/api-specs/gateway/admin-ee/<version-folder>/openapi.yaml`.
1. If there are any plugin spec updates, you can generate the plugin specs as well, as long as you know the endpoint that the plugin creates. For example, the following command will pull out `jwt` and `jwts` endpoints for the JWT plugin from the `openapi.yaml` you already generated:

   ```
   yq '.paths |= with_entries(select(.key=="*/jwt/*" or .key=="*/jwts))' work/openapi.yaml > tmp123
   npx -y oas-toolkit remove-unused-components tmp123 > tmp456
   npx -y oas-toolkit remove-unused-tags tmp456 > openapi.yaml
   rm tmp123 tmp456
   ```

   Most plugins only have one unique entity. For example, for Basic Auth, the entity is `basic-auths`. You can check the entity for any plugin by going to their API page, e.g. https://developer.konghq.com/plugins/jwt/api/.

	 > **Note**: All plugins that add unique entities to the Admin API are listed here: https://github.com/Kong/developer.konghq.com/tree/main/api-specs/plugins. However, the admin apec generator doesn't generate specs for all of these plugins. Check the generated complete `openapi.yaml` before attempting to generate a plugin spec.

1. Copy the generated spec files into `developer.konghq.com/api-specs/plugins/<plugin-name>/openapi.yaml`.

> Make sure the file is named `openapi.yaml`, otherwise the Insomnia buttons won't generate.

1. Update the file in Konnect.
  1. Log into the Konnect Prod org (use Okta).
  1. Go to API Products -> Gateway Admin EE -> Product Versions.
  1. Pick a version or create a new one.
  1. Upload the `openapi.yaml` file.

1. If this is for a new version, run the [Sync Konnect OAS Data](https://github.com/Kong/developer.konghq.com/actions/workflows/sync-konnect-oas-data.yml) GitHub action.
In the **Run workflow** dropdown, select your release branch (e.g. `release/gateway-3.12`), then click the **Run workflow** button.

### Konnect support

Update the Konnect supported versions YAML file at `app/_data/support/gateway.yml` in the following format:

```yaml
- release: "3.12"
  konnect: true
  beginning: "3.12.0.0" # first patch version that's available in konnect
  release_date: "2025-09-22"
  eol: "2026-09-22" # one year from release date for a regular release; three years from release date for an LTS release
  sunset: "2027-09-22" # two years from release date for a regular release; four years from release date for an LTS release
```

### Algolia

Update the search index:

1. Log into Algolia using team-docs (credentials in 1pass).
   
    Make sure the **kongdeveloper** application is selected.

2. Go to **Data sources** (database icon in bottom left corner) > **Crawler**.

3. Open **kongdeveloper**, then click on **Resume crawling**.

### Kapa

Update the AI assistant:

1. If there's a new API spec, add the spec to **Sources**. 
After Kapa finishes pulling the content, make sure to **Review** and then **Ingest**.

1. Re-ingest the developer site after it has been completely published & built:
   1. Go to **Sources**, find the entry for "Developer Docs", open the dropdown and click **Refresh**.
   1. After the process completes (this will take a while), click **Review** and then **Ingest**.

