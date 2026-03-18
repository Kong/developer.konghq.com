# Writing Content for LLM/RAG Markdown Output

## Overview

At build time, the site generates markdown versions of all pages into `dist/`. These are used for LLM/RAG consumption and are produced automatically — no extra steps required from authors.

Writing content with LLM output in mind improves quality for both human readers and LLM consumers. The guidelines below describe what to do (and avoid) to ensure clean output.

---

## Writing guidelines

### Avoid raw HTML

Don't use inline HTML for images, links, divs, or other elements. The generator does not strip HTML — it will appear verbatim in LLM output.

- **Images**: use `![alt text](url)` instead of `<img>`
- **Links**: use `[text](url)` instead of `<a href>`
- **Wrappers/layouts**: if you need a custom HTML wrapper, request a new liquid tag (e.g. `{% html_tag %}` already exists and discards its wrapper in markdown output)

### Use `{% table %}` and `{% feature_table %}` blocks

Don't use raw markdown tables (`| col | col |`). The `{% table %}` and `{% feature_table %}` tags have both HTML and markdown templates — they render correctly in both contexts. Raw markdown tables have no markdown conversion and may not render well structurally in LLM output.

### Avoid icons and emojis for boolean values

Don't use ✅, ❌, 🟢, 🔴, or similar icons in tables to indicate true/false/supported/not-supported. LLMs cannot reliably interpret icon semantics.

Use `{% feature_table %}` instead: set values to the string `"true"` or `"false"` and they are automatically converted to "Supported" / "Not Supported" in markdown output.

### Use semantic markdown structure

- Use heading hierarchy logically — don't skip levels (e.g. `###` directly under `#`)
- Prefer descriptive link text over bare URLs
- Write alt text for images

---

## How markdown generation works

### Overview

`app/_plugins/generators/markdown_pages_generator.rb` iterates all Jekyll pages and collection documents at build time and generates a markdown version of each, saved to `dist/`. Pages can opt out by setting `llm: false` in frontmatter.

### The `output_format` mechanism

Each liquid block and tag checks whether `page['output_format'] == 'markdown'`. When true, the tag loads a `.md` include template instead of the `.html` one. This is how the same liquid tag renders differently for the website vs. LLM output.

Markdown component templates live in `app/_includes/components/`.

### How specific elements convert

Some elements like tables and tabs are flattened so they can be interpreted by LLMs.

#### Tabs

Each tab becomes a heading followed by its content.
For example, a tab group with "Konnect" and "On-prem" tabs becomes two `###` headings with their respective content.

#### Tables

Information that depends on visual table structure often loses meaning when processed as text by LLMs. Tables are converted into a Markdown key-value format to preserve semantic relationships, with each row becoming a heading followed by its content.

In both cases, the generated markdown relies on headings. Choosing the right heading level is crucial to maintain semantic structure.
The platform decides which heading level to use based on the heading level preceding the liquid tag. For example:

```
## Example heading

{% table/navtabs %}
```
In this case, each tab or row uses `###` (h3).

#### Note:

Normally, heading level inference shouldn't affect the authoring experience, but there is one edge case to consider when using includes.
Avoid having includes that contain a table or navtabs without a preceding heading before the liquid tag.
Within the include, the platform can't know which heading level to use and it defaults to using `h3`, which may break the content's structure.

This can be avoided by passing the current heading level to the include:

```liquid
### Example heading

{% include include_with_tabs.md heading_level=3 %}
```
In this case, each tab uses `####` (h4).

### Konnect and On-prem specific content

There are [two new liquid tags](https://developer.konghq.com/contributing/#render-code-block-text-per-deployment-type) for rendering deployment-type specific content.

## Excluding pages from generation

Add `llm: false` to a page's frontmatter to exclude it from markdown generation entirely.
