{% if include.section == "question" %}

Is self-managed GitLab supported in {{site.konnect_catalog}} Classic?
{% elsif include.section == "answer" %}

No. Support for self-managed GitLab (GitLab Dedicated or Self-managed) was removed from {{site.konnect_catalog}} Classic on October 26, 2026.
If you had a GitLab self-managed integration instance, it will remain visible but can't be authorized or ingest resources.
The GitLab integration still supports GitLab.com (SaaS).

{% endif %}