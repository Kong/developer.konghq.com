---
name: bootstrap-product
description: >
  Bootstrap a brand-new product on developer.konghq.com: product data file, icon, index,
  landing page, site variable, frontmatter enum, brand colors, icon registration, top
  navigation link, and homepage card. Use whenever someone wants to bootstrap, add, set up,
  or register a new product or top-level docs section on the site, for example "bootstrap
  a new product called X", "add X to the nav and homepage", "set up a landing page and
  index for the new X product", or "do what we did for AI Cost Management for X". Not for
  adding pages to an existing product, and not for writing the landing page content itself.
---

The mechanical parts are done by `tools/bootstrap-product/index.js`. The top navigation
link and homepage card are done here, with user input. The script can't do them safely:
they depend on section and group names that are user-facing copy and get renamed, so a
text anchor would break often. Keep them in the skill.

## 1. Gather inputs

Ask the user for anything they haven't already given:

- **Name**: display name, for example `Webhook Engine`.
- **Slug**: derive it from the name (`webhook-engine`) and confirm.
- **Works on**: `konnect`, `on-prem`, or both. It sets `works_on` on the landing page.
- **Color**: one of the `--color-semantic-<name>-primary` colors defined in
  `app/_assets/stylesheets/index.css`. Default green. Read the file to list the current
  options for the user.
- **Tag**: a landing page tag. It must already exist in
  `app/_data/schemas/frontmatter/tags.json`. If it doesn't, offer to add it
  (alphabetical order, lowercase, hyphens only) before running the script.
- **Homepage description**: one sentence for the homepage card.
- **Homepage card icon**: an existing file in `app/assets/icons/` (list close matches
  if the user is unsure).

## 2. Run the script

```bash
node tools/bootstrap-product --slug <slug> --name "<Name>" --works-on <konnect|on-prem|konnect,on-prem> --color <color> --tag <tag>
```

It creates 4 files and patches 4. It checks every anchor before writing, skips anything
already done, and writes nothing if an anchor is missing. If it fails on an anchor, the
target file was restructured: fix the script's anchor, don't patch around it by hand,
or the next product will hit the same failure.

## 3. Top navigation (ask the user)

First grep `app/_data/top_navigation.yml` for `/<slug>/`. If the link already exists,
tell the user and skip this step so a rerun doesn't add a duplicate.

Otherwise read the file and list the current `- title:` sections under the platform
menu. Ask which section the product belongs in, and whether it should go at the end of
that section or somewhere specific.

Add the link in the same shape as its siblings:

```yaml
        - text: <Name>
          url: /<slug>/
          product: <slug>
```

## 4. Homepage card (ask the user)

First grep `app/_data/homepage.yml` for `/<slug>/`. If the card already exists, tell the
user and skip this step.

Otherwise read the file and list the `- name:` groups under `products_section`. Ask which
group the card belongs in and where within it.

Add the card in the same shape as its siblings, using `{{site.<slug_with_underscores>}}`
for the name:

```yaml
        - title: "{{site.<snake>}}"
          icon: /assets/icons/<icon>.svg
          description: "<description>"
          links:
            - text: "{{site.<snake>}} overview"
              url: /<slug>/
            - text: How-to guides
              url: /how-to/?products=<slug>
            - text: All documentation
              url: /index/<slug>/
```

## 5. Check and report

- Run `git status` and `git diff` and confirm only the expected files changed.
  Don't stage or commit unless asked.
- Tell the user what is still a placeholder:
  - `app/_assets/icons/products/<slug>.svg` is a generic bolt. A real 12x12 icon should
    use `fill="rgb(var(--color-<slug>-brand))"`.
  - `app/_landing_pages/<slug>.yaml` and `app/_indices/<slug>.yaml` are minimal stubs.
    `app/_landing_pages/ai-cost-management.yaml` is a good model for what a filled-in
    landing page looks like (header, intro, get-started cards, key references, how-to
    list, FAQs).
- Suggest `make run` to confirm the nav link, homepage card, and landing page render.
  It validates frontmatter before starting the server.
