# plugins-changelog-generator

Generate Gateway plugins changelogs based on Gateway's changelog (`app/_data/changelogs/gateway.json`).

## How to run it

Make sure that Gateway's changelog is up to date.
From the root of your clone of the dev site repo run the following commands to install the dependencies:

```bash
cd tools/plugins-changelog-generator
npm ci
```

Generate the entries for a specific version by running:

```bash
node run.js --version='3.11.0.0'
```

It will pull the entries from Gateway's changelog and add them to the corresponding plugins.