# Generating plugin schemas using the docs plugin toolkit

Our plugin schemas are generated via [Kong/docs-plugin-toolkit](https://github.com/Kong/docs-plugin-toolkit). 
Whenever there is a new plugin or changes to plugins in a release, we use this toolkit to update schemas for a particular release.

## Download and update all plugin schemas (GH actions)

Download and update all schemas using GitHub actions:

1. (Optional) If you're adding a new plugin, you need to set up the directory for it before running any GitHub actions:
    1. Clone https://github.com/Kong/docs-plugin-toolkit.
    1. Add a folder for the new plugin at `/schemas/<plugin-name>` with a `.gitkeep` file, so that the empty directory gets pushed to GitHub:
        ```sh  
        mkdir schemas/plugin-name
        touch schemas/plugin-name/.gitkeep
        ```
    1. Push your changes to a branch.
1. Run [Download Schemas](https://github.com/Kong/docs-plugin-toolkit/actions/workflows/download-schemas.yml). 
Click "Run workflow" and fill in the following:
    * Branch: whatever branch you're using for your update.
    * Docker image tag: e.g. `3.12.0.0`; If using a dev image, the tag can be anything - a PR, `latest`, `master`, an RC image, etc.
    * Kong Gateway release: the minor release in `3.12.x` format.
    * Docker image name: `kong-gateway` for public releases, `kong-gateway-dev` for internal Docker images, such as nightly or preview builds.
1. Run [Generate Plugin Priorities](https://github.com/Kong/docs-plugin-toolkit/actions/workflows/generate-plugin-priorities.yml) against the same branch as the previous step.
1. Run [Generate JSON Schemas](https://github.com/Kong/docs-plugin-toolkit/actions/workflows/generate-json-schemas.yml) against the same branch.
1. Run [Generate Referenceable Fields](https://github.com/Kong/docs-plugin-toolkit/actions/workflows/generate-referenceable-fields.yml) against the same branch.
1. Review and merge the generated PR, which should contain changes from all 4 GitHub actions. 
   
   This will kick off an action on the developer.konghq.com repo, and automatically open a PR against that repo.

## Download and update schemas manually

In most cases, you can use GH actions (see above) to generate plugin schemas and other data.
In some situations though, you might want to generate schemas manually - for instance, if you only want to update one plugin, or if you need to combine the output from different branches.

1. Clone https://github.com/Kong/docs-plugin-toolkit.
1. Run Kong Gateway locally. The easiest way is to use the quickstart (make sure that `KONG_LICENSE_DATA` is set):
   
   ```sh
   curl -Ls https://get.konghq.com/quickstart | bash -s -- -e KONG_LICENSE_DATA -i kong-gateway-dev -a kong-312 -t latest
   ```

   * `-i` is the image name, `kong-gateway` by default. Use `kong-gateway-dev` for preview and internal images.
   * `-a` is the container name. This is optional, but helpful for organization.
   * `-t` is the tag. This can be a PR, `latest`, `master`, and RC image, etc.
1. In your terminal, navigate to wherever you cloned `Kong/docs-plugin-toolkit`.
1. Run `bundler install` to get the prerequisites.
1. Download the schema for your plugin:
   
   ```sh
   ./plugins download_schemas --version=3.12.x --plugins ai-mcp-proxy
   ```
   Repeat as necessary for any other plugins.
1. Generate plugin priorities:

   ```sh
   ./plugins generate_plugin_priorities --type=ee --version 3.12.x
   ```
1. Convert the schemas to JSON schemas:

   ```sh
   ./plugins convert_json_schema --version 3.12.x --plugins $(ls ./schemas)
   ```

   You can pass the plugin name or convert all plugins at once.

1. Generate referenceable fields:

   ```sh
   ./plugins generate_referenceable_fields_list --version 3.12.x --plugins $(ls ./schemas)
   ```
1. Commit and open a PR with your changes. 

   This will kick off an action on the developer.konghq.com repo, and automatically open a PR against that repo.
