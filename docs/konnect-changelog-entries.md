# Writing a Konnect changelog entry

Konnect's changelog is authored directly in this repo. Each entry is one YAML file — add yours in the same PR as the change it describes (or right before you ship it), and it publishes automatically on merge.

## Adding an entry

1. Create a new file in `app/_data/changelogs/konnect/`, named after your change, e.g. `download-dashboards-as-pdf.yml`.
2. Fill it in using this template:

```yaml
title: "Download dashboards as PDF"
date: 2026-07-31
content: |
  You can now download any dashboard as a PDF directly from the dashboard menu.
  The exported PDF is print-friendly and contains a link back to the live dashboard.
url: https://releases.konghq.com/en/download-dashboards-as-pdf-Nq9NwICE
```

| Field | Required | Notes |
|---|---|---|
| `title` | Yes | Short, user-facing summary of the change. |
| `date` | Yes | `YYYY-MM-DD`. |
| `content` | Yes | Full description. Markdown is fine. |
| `url` | No | Link to a demo, related doc, or the original announcement. |

3. Run `make validate-konnect-changelog` locally to catch typos or missing fields before opening your PR.
4. Open the PR. On merge, the entry renders at `/konnect-platform/changelog/` and in the RSS feed at `/konnect-platform/changelog/feed.xml`.

Do not add a file named `template.yml` (or anything else you don't want published) to `app/_data/changelogs/konnect/` — every file in that directory is loaded and rendered as a real entry.
