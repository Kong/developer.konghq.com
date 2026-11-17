# developer.konghq.com

🦍 Source code for developer.konghq.com website.

## Prerequisites

- [mise](https://mise.jdx.dev/getting-started.html).
    - Optionally configure your shell to [activate mise](https://mise.jdx.dev/getting-started.html#activate-mise) automatically.
    - You may need to run `mise trust` when first opening a new repository.
- [libyaml](https://github.com/yaml/libyaml).

## Run Locally

```bash
# Install dependencies
make install

# Create local .env file
# OAS Pages require VITE_PORTAL_API_URL to be set in your current environment, it should match the Kong supplied portal URL
cp .env.example .env

# Build the site and watch for changes 
make run
```

Once you see the `Server now ready on …` message, the docs site is available at [http://localhost:8888](http://localhost:8888). The entry URL is also written to `tmp/dev-url`.

> Note: By default, some page generation is skipped for performance reasons. To generate the entire site locally, go to `jekyll-dev.yml` in the root of the repo and comment out the entire `skip` section.

## Parallel dev servers (worktrees)

All four dev server ports (Netlify proxy, Jekyll, Vite, livereload) derive from a single port offset. The primary checkout always uses offset 0 and serves the site at [http://localhost:8888](http://localhost:8888).

When `make run` runs inside a linked git worktree, `exe/dev-ports` claims an offset for that worktree automatically (10, 20, and so on) and persists it in a gitignored `.dev-ports` file, so several worktrees can serve the site at the same time. The entry URL is printed at startup and written to `tmp/dev-url`.

To pin the ports for one invocation, set `PORT_OFFSET`; for example, `PORT_OFFSET=20 make run` serves the site at `http://localhost:8908`. The persisted claim is not rewritten. `make kill-ports` stops only the current checkout's ports; if you started the stack with a `PORT_OFFSET`, pass the same value to `make kill-ports`.

Tooling that targets the dev server accepts a `BASE_URL` environment variable, defaulting to `http://localhost:8888`:

```sh
BASE_URL=http://localhost:8908 npm run generate-instruction-files --prefix tools/automated-tests
```

## Generating specific products locally

Building the entire docs site can take a while. To speed up build times, you can generate a specific subset of products by setting the `KONG_PRODUCTS` environment variable. This variable accepts a comma-separated list of products (product slugs as defined in `app/_data/products`), e.g `KONG_PRODUCTS=ai-gateway make run`.

## Generating specific pages locally

You can generate specific pages by setting the `PAGE_PATHS` environment variable. This variable accepts a comma-separated list of paths. For example:

```sh
PAGE_PATHS="/plugins/acme/,/gateway/entities/" make run
```

The platform will generate all pages that match each specified path. For instance, `/gateway/entities/` will generate all pages whose paths start with `/gateway/entities/`.

## Building against a different Konnect environment

By default, `{% konnect_api_request %}` renders commands against `konghq.com`. To render against the internal `konghq.tech` environment instead, set `KONNECT_DOMAIN=konghq.tech` when building, e.g. `KONNECT_DOMAIN=konghq.tech make run`.

## Contributing to the docs

If you want to contribute to the Kong Developer docs, see the [Contributing guide](https://developer.konghq.com/contributing/).
