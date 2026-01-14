# developer.konghq.com
🦍 Source code for developer.konghq.com website.

## Run Locally

Make sure you have [mise](https://mise.jdx.dev/getting-started.html)

If you want to make sure you will always use the right version of tools, [activate mise](https://mise.jdx.dev/getting-started.html#activate-mise).

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

> Note: By default, some page generation is skipped for performance reasons. To generate the entire site locally, go to `jekyll-dev.yml` in the root of the repo and comment out the entire `skip` section.

## Generating specific products locally

Building the entire docs site can take a while. To speed up build times, you can generate a specific subset of products by setting the `KONG_PRODUCTS` environment variable. This variable accepts a comma-separated list of products (product slugs as defined in `app/_data/products`), e.g `KONG_PRODUCTS=ai-gateway make run`.

## Contributing to the docs

If you want to contribute to the Kong Developer docs, see the [Contributing guide](https://developer.konghq.com/contributing/).
