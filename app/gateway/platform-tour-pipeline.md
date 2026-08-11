---
title: "Platform Tour: Shipping"
permalink: /reference/platform-tour-pipeline/
content_type: reference
layout: reference
description: "How a commit actually becomes a live page: real PR checks, a real Netlify preview URL, and the CDN that serves production."
products:
  - gateway
  - ai-gateway
works_on:
  - on-prem
  - konnect
tools:
  - deck
tags:
  - ai
  - konnect
related_resources:
  - text: "Platform Tour: the hub"
    url: /internal/platform-tour-landing/
  - text: "Platform Tour: the how-to page"
    url: /how-to/platform-tour/
  - text: "Platform Tour: the reference page"
    url: /reference/platform-tour-reference/
  - text: "Platform Tour: the demo plugin"
    url: /plugins/platform-tour-demo/
  - text: "Platform Tour: Testing"
    url: /how-to/platform-tour-testing/
seo_noindex: true
---

{% include platform-tour/orientation.md part=5 note="The last part" %}

Every earlier page in this tour traced one write to many outputs. [Part 4](/how-to/platform-tour-testing/)
traced how much of that output actually gets verified. This page follows the same commit the rest of the way,
from a contributor's PR to a real URL in a real reader's browser.

## Diagram of the deployment pipeline

{% mermaid %}
flowchart TD
    A[Contributor commits] --> B[GitHub PR opened]
    B --> C1[linting.yml: Vale, 2 passes]
    B --> C2[validate-frontmatters.yml]
    B --> C3[validate-plugin-examples.yml]
    B --> D[Netlify's GitHub App builds a deploy preview]
    D --> E["deploy-preview-N--kongdeveloper.netlify.app"]
    E --> F[check-links.yml + missing-redirects.yaml test THAT live preview]
    B -->|merge to main| G[Netlify: production build, JEKYLL_ENV=production]
    G --> H[Netlify's CDN]
    H --> I[developer.konghq.com, in the browser]
{% endmermaid %}

Two things worth noticing: the preview build isn't a GitHub Actions step at all. It's Netlify's own GitHub App
reacting to the PR directly, outside this repo's own CI. The link checker also doesn't read the Markdown
source to decide if a link works. It waits for the real preview to finish building, then clicks the real link
on the real rendered page.

## Every check that actually gates a PR

*Confirmed from each workflow file's own `on:` block, not assumed from the diagram above.*

| Workflow | Runs on | What it checks |
|---|---|---|
| `linting.yml` (Vale) | Every PR | Prose spelling, grammar, and style, twice |
| `validate-frontmatters.yml` | Every PR | Every changed page's frontmatter against its JSON Schema |
| `validate-plugin-examples.yml` | Every PR | Every plugin example's `config:` against its real schema |
| `check-links.yml` | Every PR | Broken links, checked against the live deploy preview |
| `missing-redirects.yaml` | Every PR | Pages that changed URL without a matching redirect |
| `security.yaml` | Every push | GitHub Actions pinned to a commit SHA, not a mutable tag |

{:.info}
> **Not everything runs this often.** `tools/automated-tests`, the how-to-instruction tests from
> [part 4](/how-to/platform-tour-testing/), is wired to `automated-tests.yaml`. That workflow runs on a daily
> schedule and by manual trigger, not on every pull request. `event-gateway-tests.yaml` runs monthly. A how-to's
> instructions can go stale for hours before the next scheduled run catches it, not seconds. The diagram above
> only shows the checks genuinely wired to `pull_request`.

## Automated prose and style checks

*`.github/workflows/linting.yml`: Vale, run twice, on every PR.*

A platform that generates hundreds of pages from shared templates can't rely on every reviewer catching every
style slip or misspelling by eye. One bad word in a shared include would repeat everywhere it's used. So this
runs on every pull request, not on a schedule:


**Renders as (real CI configuration):**

{% raw %}
```yaml
# .github/workflows/linting.yml (excerpt)
on:
  pull_request:
    types: [synchronize, ready_for_review, opened, labeled]

jobs:
  vale:
    steps:
      - uses: errata-ai/vale-action@...      # pass 1: raw file, body + frontmatter scalars
      - run: node tools/vale-frontmatter/index.js $CHANGED_FILES   # strips to just spell/grammar-checkable fields
      - uses: errata-ai/vale-action@...      # pass 2: the stripped frontmatter
```
{% endraw %}

It genuinely runs twice, on purpose, on different content: once on the file as written, once on a
frontmatter-only transform that isolates fields like `title`, `description`, and `tldr.q`/`tldr.a` so they get
checked too, not just page bodies. Both passes are `fail_on_error: true`. A real spelling or style violation
blocks the PR instead of just warning.

## Deploy previews

*`.github/workflows/check-links.yml` / `missing-redirects.yaml`.*

Every PR to this repo gets a real, unique, working preview URL, built automatically, before anyone reviews it:

{% raw %}
```yaml
# .github/workflows/check-links.yml (excerpt)
- uses: jakepartusch/wait-for-netlify-action@...
  with:
    site_name: "kongdeveloper"
- run: node run.js pr --base_url https://deploy-preview-${{ github.event.pull_request.number }}--kongdeveloper.netlify.app
```
{% endraw %}

That URL pattern is deterministic: `deploy-preview-<PR number>--kongdeveloper.netlify.app`. Two separate
workflows wait for it to finish, then run real checks against it. `check-links.yml` looks for broken links.
`missing-redirects.yaml` looks for pages that changed URL without a redirect. Neither one checks the Markdown
source. Both check the same page a reviewer would actually click through.

{:.info}
> **The same theme as the testing page, in a different system:** page 4 of this tour showed how-to steps and
> plugin examples getting checked against the real thing instead of the written intent. This is that same idea
> applied to the docs platform's own delivery pipeline. The checks run against a live, deployed preview, not
> against what the Markdown was supposed to produce.

## Merge, then the CDN

`netlify.toml` defines the production build context separately from the preview one:

{% raw %}
```ini
[context.production.environment]
  JEKYLL_ENV = "production"
  BUNDLE_WITHOUT = "development"

[context.deploy-preview.environment]
  JEKYLL_ENV = "preview"
  BUNDLE_WITHOUT = "development"
```
{% endraw %}

Once a PR merges to `main`, Netlify rebuilds in the `production` context and publishes the result to its CDN,
the same infrastructure that just finished serving that PR's preview build, now serving the real site. For a
docs site this size that means two things: a reader anywhere gets the page from a nearby edge location instead
of one origin server, and a merged change is live in minutes, not on the next scheduled release.

## The tour, end to end

Write once (parts 1 through 3), verify what you can (part 4), ship it checked against the real live thing, not
just the source (this page). That's the thesis this tour opened with:

- [1. The how-to page](/how-to/platform-tour/)
- [2. The reference page](/reference/platform-tour-reference/)
- [3. The demo plugin](/plugins/platform-tour-demo/)
- [4. Testing](/how-to/platform-tour-testing/)
- [The tour hub](/internal/platform-tour-landing/)
