<!--vale off-->

# Konnect Screenshots

Screenshots are captured using the [kong-product-org/shot-scraper](https://github.com/kong-product-org/shot-scraper) fork. Screenshot configs and macros live in that repo. Output images are written to `app/assets/images/` in this repo.

## Setup

Clone the fork and install:

```bash
git clone https://github.com/kong-product-org/shot-scraper
cd shot-scraper
make install
```

## Authentication

```bash
make set-env   # prints the export command — add it to your shell profile
make auth      # opens a browser to log in to Konnect
```

## Taking screenshots

Run from inside the shot-scraper repo:

```bash
make screenshot konnect/platform/overview.yaml
```

If your docs repo is not at `../developer.konghq.com`, pass the path explicitly:

```bash
make screenshot konnect/platform/overview.yaml DOCS_DIR=/path/to/developer.konghq.com
```

Available configs:

```
konnect/ai-manager/
konnect/analytics/
konnect/catalog/
konnect/datakit/
konnect/debugger/
konnect/dev-portal/
konnect/event-gateway/
konnect/gateway-manager/
konnect/mesh-manager/
konnect/platform/
```
