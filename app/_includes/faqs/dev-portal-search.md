{% if include.section == "question" %}

How does search work in {{site.dev_portal}}, and how do I turn on semantic search?

{% elsif include.section == "answer" %}

{{site.dev_portal}} search can run in two modes:

* **Keyword search** (default): Matches on exact text, phrases, and fuzzy
  matches of your query terms.
* **Semantic search**: Adds a meaning-based ranking on top of keyword
  matching. It can surface relevant pages and API documentation even when the
  query doesn't share exact words with the content. For example, it can find a
  page about "rate limiting" when a developer searches for "how do I control
  how often someone can call my API."

Both modes run as a single search, scoped to your {{site.dev_portal}}.

To enable semantic search, do the following:

1. In the {{site.konnect_short_name}} sidebar, expand **Dev Portal** and click **Portals**.
1. Click your {{site.dev_portal}}.
1. Click the **Settings** tab.
1. Click the **AI** tab.
1. Enable **AI enhanced search**.
1. Click **Save changes**.

{% endif %}
