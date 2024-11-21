# vale-frontmatter

By default, Vale ignores frontmatters.
This tool provides a workaround, allowing Vale to analyze frontmatters by overwriting Markdown files with the content of their frontmatter (without the delimiters). This enables Vale to treat the frontmatter as Markdown and perform the corresponding checks while maintaining accurate error reporting (line and column numbers).

## How it works

1. Takes a single file/directory or a JSON-formatted list of files. Defaults to `app/**/*.md` if no arg is present.
2. Loads a list of keys for Vale to ignore from `.github/styles/docs/Frontmatter.txt`.
3. For each file, the tool:
   1. Extracts the frontmatter.
   2. Replaces each matching key's line with an empty string.
   3. Overwrites the file's content with the modified frontmatter (without delimiters).

## Note

This tool is not intended for local use.
However, if you want to try it, make sure to stage all your changes first (git add), as any unstaged changes will be lost.

## How to run it

In the current directory:

``` bash
npm ci
node index.js
```

## Run Vale

In the root directory, run Vale on the modified files
`vale --config=./.vale.ini app/**/*.md`.
