Not everything on this platform started as a Markdown file in this repo. Every system below has
its real source of truth in a different repo entirely. Two different mechanisms bring that
content in, and one of them turned out to be dormant.

{% table %}
columns:
  - title: System
    key: system
  - title: Source
    key: source
  - title: Mechanism
    key: mechanism
  - title: Auto-generates the page?
    key: auto
rows:
  - system: Inso CLI reference
    source: "`Kong/insomnia`"
    mechanism: "GitHub Action checks out the repo, runs the real `inso generate-docs` command, copies the output, opens a PR."
    auto: "Yes"
  - system: Plugin/Gateway changelogs
    source: "`Kong/kong-ee`"
    mechanism: "GitHub Action checks out the repo, parses raw changelog markdown, opens a PR."
    auto: "Yes (the changelog tab)"
  - system: kongctl reference
    source: Compiled kongctl binary
    mechanism: "GitHub Action installs the real binary, scrapes `--help` output, writes snippets, opens a PR. Auto-deletes wrapper pages for dropped commands."
    auto: "No, a hand-written wrapper page transcludes the snippet"
  - system: decK reference
    source: Compiled decK binary
    mechanism: "Same help-scraping pattern as kongctl, no stale-page pruning."
    auto: "No, same hand-written-wrapper pattern"
  - system: Skills Hub
    source: "`Kong/ai-marketplace`"
    mechanism: "True git submodule. At build time, a generator reads skill files straight out of it."
    auto: "Yes, entirely, no human step"
  - system: Kuma → Mesh
    source: "`kumahq/kuma-website`"
    mechanism: "True git submodule. A build-time generator can auto-convert pages, but its page list is empty today."
    auto: "Used to, automatically. Today, no."
{% endtable %}
