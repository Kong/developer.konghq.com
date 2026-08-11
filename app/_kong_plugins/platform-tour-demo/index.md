---
title: 'Platform Tour Demo'
name: 'Platform Tour Demo'

content_type: plugin

publisher: kong-inc
description: 'A local-only demo plugin created to show how a brand-new plugin gets its overview, reference, example, and changelog pages generated automatically from one schema file.'

products:
    - gateway

works_on:
    - on-prem

third_party: true
license_type: Apache-2.0

icon: mocking.png

categories:
  - traffic-control

min_version:
  gateway: '3.0'
seo_noindex: true
---

This plugin does not exist in {{site.base_gateway}}. It's a local-only demo, and this very page is the
demonstration. Everything that follows was written once, in this file and two others, and shipped to four
different destinations without anyone laying out a single one of them by hand.

{% include platform-tour/orientation.md part=3 %}

One real manual step was needed to see this: `jekyll-dev.yml` skips plugin reference/example/API page
generation by default in local dev, to keep everyday rebuilds fast. Seeing the full set of pages meant
temporarily commenting out `skip.plugins: true` there and restarting the dev server. That's a real, shared
dev-speed setting, reverted once this tour is done with it. Everything past that one step is generated, not
hand-built.

## Three files in, four pages out

*134 of 134 real plugins get this same treatment: 100% coverage, one generator.*

**Writer types:** the whole plugin, three files:

{% raw %}
```yaml
# _kong_plugins/platform-tour-demo/schema.json (excerpt)
{
  "properties": {
    "config": {
      "properties": {
        "greeting": { "type": "string", "default": "Hello from the platform tour" },
        "header_name": { "type": "string", "default": "X-Platform-Tour-Demo" }
      }
    }
  }
}
```

```yaml
# _kong_plugins/platform-tour-demo/examples/enable-platform-tour-demo.yaml
title: 'Enable the platform tour demo plugin'
config:
  greeting: "Hello from the platform tour"
  header_name: "X-Platform-Tour-Demo"
tools: [deck, admin-api, konnect-api, kic, terraform]
```
{% endraw %}

**Renders as (live, these are real, generated pages, not mockups, including this one):**

- **This overview page**: built from this file's frontmatter and the prose you're reading right now.
- [Reference](/plugins/platform-tour-demo/reference/): built entirely from `schema.json`. The `.md` file
  behind it is two lines long.
- [Example](/plugins/platform-tour-demo/examples/enable-platform-tour-demo/): the same `entity_example`-style
  tool tabs (decK, Admin API, Konnect API, KIC, Terraform) as the how-to tour's Service demo, generated from
  one YAML file.
- **Changelog**: no page at all right now, not even an empty one. `generate_changelog_page` checks
  `plugin.changelog_exists?` first and skips generating the page entirely if there's no `changelog.json`
  (confirmed: `/plugins/platform-tour-demo/changelog/` 404s). That's the honest state of a plugin on day one,
  before its first release entry exists.

## A real limit in the plugin config validator

*`tools/plugin-examples-validator`: checks plugin example configs against real Kong Gateway schemas.*

Every plugin's `examples/*.yaml` is supposed to get its `config:` block checked against the plugin's real JSON
schema. Here's the output from running it against this whole repo, including this plugin:

```
$ node tools/plugin-examples-validator/index.js
Using schema version: 3.15
Found 500 example files

SKIP: No schema found for "platform-tour-demo"
...
Skipped: 24
Errors: 0

All plugin examples are valid.
```

The validator only checks `app/_schemas/gateway/plugins/<version>/`, the versioned, auto-synced schemas for
Kong's **first-party** plugins. This plugin's `schema.json` lives locally in its own folder, the same way 22
real **third-party** plugins' schemas do (Moesif, Kong Upstream JWT, and others). None of those 24 plugins'
examples are checked by this tool, so their config could be wrong today and nothing would catch it. That's the
validator's real, current scope (`tools/plugin-examples-validator/index.js:97-104`), not a gap this demo
introduced.

## See the rest of the tour

- [1. The how-to page](/how-to/platform-tour/): entity_example tabs, the Konnect/on-prem switch, a validation block that doubles as an automated test.
- [2. The reference page](/reference/platform-tour-reference/): the same one-input-many-outputs idea as a mermaid diagram, plus a live-fetched parameter table.
- [4. Testing](/how-to/platform-tour-testing/): where docs-testing coverage *does* reach all the way to a real, running gateway, next to this page's validator gap.
- [5. Shipping, the finale](/reference/platform-tour-pipeline/): a real PR preview URL, automated Vale checks, and the CDN that serves production.
- [The tour hub](/internal/platform-tour-landing/)
