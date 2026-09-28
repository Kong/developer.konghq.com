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

Once you see the `Server now ready on …` message, the docs site is available at [http://localhost:8888](http://localhost:8888).

### OIDC login

Set `OIDC_ISSUER`, `OIDC_CLIENT_ID`, and `OIDC_CLIENT_SECRET` in `.env` for local development and in the Netlify environment for deployed sites. Register `http://localhost:8888/auth/callback` as a redirect URI locally, and `https://<site-domain>/auth/callback` for each deployed domain that supports login. Use the Netlify dev server on port 8888 for local login; port 4000 serves Jekyll without the Netlify functions. Login requests opened at `127.0.0.1` move to `localhost` before authentication. The provider must support authorization code flow, PKCE (S256), client secret basic authentication, and a signed ID token with a published JWKS.

The Netlify login function discovers the provider from `OIDC_ISSUER`. After validating the ID token, the callback uses the access token to call Konnect's `/v3/users/me` and `/v3/organizations/me` endpoints. It stores the ID token under `oidc_id_token`, the user's `preferred_name` (or `full_name` when missing) under `oidc_preferred_name`, and the organization's `name` under `oidc_organization_name` in browser local storage. The header shows `Hello <name> from <org_name>` until the ID token expires. If the organization lookup fails, it shows `Hello <name>`; if the user lookup fails, it falls back to the token's `sub`. Log out clears all three local values; it does not end the provider session.

For local token inspection, set `OIDC_DEBUG_TOKENS='true'` in `.env` and log in again through the Netlify dev server. The callback prints the access token in the dev server terminal only for loopback requests. Leave this setting unset in deployed environments.

> Note: By default, some page generation is skipped for performance reasons. To generate the entire site locally, go to `jekyll-dev.yml` in the root of the repo and comment out the entire `skip` section.

## Generating specific products locally

Building the entire docs site can take a while. To speed up build times, you can generate a specific subset of products by setting the `KONG_PRODUCTS` environment variable. This variable accepts a comma-separated list of products (product slugs as defined in `app/_data/products`), e.g `KONG_PRODUCTS=ai-gateway make run`.

## Generating specific pages locally

You can generate specific pages by setting the PAGE_PATHS environment variable. This variable accepts a comma-separated list of paths. For example:

```sh
PAGE_PATHS="/plugins/acme/,/gateway/entities/" make run
```

The platform will generate all pages that match each specified path. For instance, `/gateway/entities/` will generate all pages whose paths start with `/gateway/entities/`.

## Building against a different Konnect environment

By default, `{% konnect_api_request %}` renders commands against `konghq.com`. To render against the internal `konghq.tech` environment instead, set `KONNECT_DOMAIN=konghq.tech` when building, e.g. `KONNECT_DOMAIN=konghq.tech make run`.

## Contributing to the docs

If you want to contribute to the Kong Developer docs, see the [Contributing guide](https://developer.konghq.com/contributing/).
