# frontmatter-validator

Validate pages' frontmatter against the schema.

## How it works

1. Loads the frontmatter schemas defined in `app/_data/schemas/frontmatter`.
2. Validates the frontmatter of pages against the corresponding schemas.

## How to run it

In the current directory:

``` bash
npm ci
node index.js
```
