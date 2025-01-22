# kong-conf-to-json

Parse kong.conf and stores a json representation in `app/_data/kong-conf/<version>.json`.

## How it works

`kong-conf-to-json` requires `kong/kong-ee` to be available locally.
From the root of your clone of the dev site repo:

```bash
cd kong-conf-to-json
npm ci
```

## How to run it

Transform a `kong.conf` file to `json` format by passing the relative path to the `kong.conf` file and its `version`, e.g.

`node run --file=../../../kong.conf.default --version=3.9`

will parse the file and write it to `app/_data/kong-conf/3.9.json`.
