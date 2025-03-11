# kong-conf-to-json

Parse kong.conf and stores a json representation in `app/_data/kong-conf/<version>.json`.
Generate a json representation of kong.conf in `app/_data/kong-conf/index.json` with the version information of each field.

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


### Index file generation

After generating the fiels for each version in the previous step, the `index.json` file can be generated.

`node index-file`

will generate a json file containing the version information for each param and store it in `app/_data/kong-conf/index.json`.